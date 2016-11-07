//
//  Command.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/10/16.
//
//

import Foundation
import SwiftyJSON

// MARK: - VimCommand

/// With a JSON channel the process can send commands to Vim that will be
/// handled by Vim internally, it does not require a handler for the channel.
///
/// Possible commands are:
///
///   - `redraw`: redraw the screen
///   - `ex`: an ex command
///   - `normal`: a normal-mode command
///   - `expr`: an expression, with an optional response requested
///   - `call`: call a Vim function, with an argument list, and an optional response
///
/// With all of these: Be careful what these commands do!  You can easily
/// interfere with what the user is doing.  To avoid trouble use `mode()` to check
/// that the editor is in the expected state.  E.g., to send keys that must be
/// inserted as text, not executed as a command:
///
/// ````
/// ["ex","if mode() == 'i' | call feedkeys('ClassName') | endif"]
/// ````
///
/// Errors in these commands are normally not reported to avoid them messing up
/// the display.  If you do want to see them, set the 'verbose' option (in Vim) 
/// to 3 or higher.
public struct VimCommand {
  /// The internal enum we use to build the command.
  let _command: CommandKind

  /// Create a VimCommand.
  ///
  /// - parameter command: The enum value used to build the command.
  init(_ command: CommandKind) {
    self._command = command
  }

  /// Represents the kind of command that can be sent to Vim over a channel.
  /// 
  /// We separate this from `VimCommand` so we can have default values when
  /// constructing each command.
  enum CommandKind {
    /// A redraw command. 
    case redraw(Bool)
    /// An ex-mode command.
    case ex(String)
    /// A normal-mode command.
    case normal(String)
    /// Evaluate an expression.
    case expr(String, Int?)
    /// Call a vim function.
    case call(String, JSON, Int?)
  }
}

// MARK: - JSONSerializable

extension VimCommand: JSONSerializable {
  public var json: JSON {
    switch self._command {
    case .redraw(let forced):
      return ["redraw", forced ? "force" : ""]

    case .ex(let command):
      return ["ex", command]

    case .normal(let command):
      return ["normal", command]

    case .expr(let expression, let id):
      if let id = id {
        return ["expr", expression, id]
      } else {
        return ["expr", expression]
      }

    case .call(let fn, let args, let id):
      if let id = id {
        return ["call", fn, args, id]
      } else {
        return ["call", fn, args]
      }
    }
  }

  public func jsonString(using encoding: String.Encoding) -> String? {
    return json.rawString(encoding)
  }

  public func rawData() throws -> Data {
    return try json.rawData()
  }
}

// MARK: - Static Methods

extension VimCommand {
  /// Create a redraw command.
  ///
  /// The other commands do not update the screen, so that you can send a sequence
  /// of commands without the cursor moving around.  You must end with the "redraw"
  /// command to show any changed text and show the cursor where it belongs.
  ///
  /// - parameter forced: Whether the `redraw` should be forced.
  ///
  /// - returns: a `Redraw` command.
  public static func redraw(forced: Bool = false) -> VimCommand {
    return VimCommand(.redraw(forced))
  }

  /// Create an ex command.
  ///
  /// The "ex" command is executed as any Ex command.  There is no response for
  /// completion or error.  You could use functions in an autoload script:
  ///
  /// ````
  /// VimCommand.ex("call myscript#MyFunc(arg)")
  /// ````
  ///
  /// You can also use "call feedkeys()" to insert any key sequence.
  ///
  /// When there is an error a message is written to the channel log, if it exists,
  /// and v:errmsg is set to the error.
  ///
  /// - parameter command: The command to execute.
  ///
  /// - returns: an `Ex` command.
  public static func ex(command: String) -> VimCommand {
    return VimCommand(.ex(command))
  }

  /// Create a normal-mode command.
  ///
  /// The "normal" command is executed like with ":normal!", commands are not
  /// mapped.
  ///
  /// Example to open the folds under the cursor:
  /// ````
  /// VimCommand.Normal("zO")
  /// ````
  ///
  /// - parameter command: The command to execute.
  ///
  /// - returns: a `Normal`-mode command.
  public static func normal(command: String) -> VimCommand {
    return VimCommand(.normal(command))
  }

  /// Create an expression command.
  ///
  /// The "expr" command can be used to get the result of an expression.  For
  /// example, to get the number of lines in the current buffer:
  /// ````
  /// VimCommand.Expr("line('$')", -2)
  /// ````
  ///
  /// It will send back the result of the expression:
  /// ````
  /// [-2, "last line"]
  /// ````
  ///
  /// The format is:
  /// ````
  /// [{number}, {result}]
  /// ````
  ///
  /// Here `{number}` is the same as what was in the request.  Use a negative number
  /// to avoid confusion with message that Vim sends.  Use a different number on
  /// every request to be able to match the request with the response.
  ///
  /// `{result}` is the result of the evaluation and is JSON encoded.  If the
  /// evaluation fails or the result can't be encoded in JSON it is the string
  /// "ERROR".
  ///
  /// Command "expr" without a response:
  ///
  /// This command is similar to "expr" above, but does not send back any response.
  ///
  /// Example:
  /// ````
  /// VimCommand.Expr("setline('$', ['one', 'two', 'three'])")
  /// ````
  ///
  /// There is no second argument in the request.
  ///
  /// - parameter expression: The expression to evaluate.
  /// - parameter id: An optional id. If this is set, Vim will send a response.
  ///
  /// - returns: an `Expr` command.
  public static func expr(_ expression: String, id: Int? = nil) -> VimCommand {
    return VimCommand(.expr(expression, id))
  }

  /// Create an function call command.
  ///
  /// This is similar to "expr", but instead of passing the whole expression as a
  /// string this passes the name of a function and a list of arguments.  This
  /// avoids the conversion of the arguments to a string and escaping and
  /// concatenating them.  Example:
  /// ````
  /// VimCommand.Call("line", ["$"], -2)
  /// ````
  ///
  /// Leave out the third argument if no response is to be sent:
  /// ````
  /// VimCommand.Call("setline", ["$", ["one", "two", "three"]])
  /// ````
  ///
  /// - parameter function: The name of the function to call.
  /// - parameter args: A json-compatible array with arguments to the function.
  /// - parameter id: An optional id. If this is set, Vim will send a response.
  ///
  /// - returns: a `Call` command.
  public static func call(function: String, args: JSON, id: Int? = nil) -> VimCommand {
    return VimCommand(.call(function, args, id))
  }
}
