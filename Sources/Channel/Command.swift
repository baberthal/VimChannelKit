//
//  Command.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/10/16.
//
//

import Foundation
import SwiftyJSON

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
/// the display.  If you do want to see them, set the 'verbose' option to 3 or
/// higher.
public enum VimCommandKind {
  case redraw
  case ex
  case normal
  case expr
  case call
}

/// Protocol that describes a type of vim command
public protocol VimCommandLike: JSONSerializable {
  /// The `kind` of command. See (`VimCommandKind`)
  static var kind: VimCommandKind { get }
}

public final class VimCommand {
  /// The other commands do not update the screen, so that you can send a sequence
  /// of commands without the cursor moving around.  You must end with the "redraw"
  /// command to show any changed text and show the cursor where it belongs.
  public struct Redraw: VimCommandLike {
    public static let kind: VimCommandKind = .redraw

    /// Set this to `true` if the redraw should be forced.
    public let forced: Bool

    /// Create a new `redraw` command.
    ///
    /// - parameter forced: True if the redraw should be forced (`redraw!`)
    public init(_ forced: Bool = false) {
      self.forced = forced
    }

    public var json: JSON {
      return ["redraw", forced ? "force" : ""]
    }
  }

  /// The "ex" command is executed as any Ex command.  There is no response for
  /// completion or error.  You could use functions in an autoload script:
  ///
  /// ````
  /// VimCommand.Ex("call myscript#MyFunc(arg)")
  /// ````
  ///
  /// You can also use "call feedkeys()" to insert any key sequence.
  ///
  /// When there is an error a message is written to the channel log, if it exists,
  /// and v:errmsg is set to the error.
  public struct Ex: VimCommandLike {
    public static let kind: VimCommandKind = .ex

    /// The ex command to be executed
    public var command: String

    /// Create a new `ex` command to send to vim.
    ///
    /// - parameter command: The `ex` command to execute.
    public init(_ command: String) {
      self.command = command
    }

    public var json: JSON {
      return ["ex", command]
    }
  }

  /// The "normal" command is executed like with ":normal!", commands are not
  /// mapped.
  ///
  /// Example to open the folds under the cursor:
  /// ````
  /// VimCommand.Normal("zO")
  /// ````
  public struct Normal: VimCommandLike {
    public static let kind: VimCommandKind = .normal

    /// The `normal` command to be executed
    public var command: String

    /// Create a new `normal` command to send to vim.
    ///
    /// - parameter command: The `normal` command to execute.
    public init(_ command: String) {
      self.command = command
    }

    public var json: JSON {
      return ["normal", command]
    }
  }

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
  public struct Expr: VimCommandLike {
    public static let kind: VimCommandKind = .expr

    /// The `expression` to be evaluated
    public var expression: String

    /// An optional message number.  This is nil by default.
    /// If this is set, vim will send a response to the expression command,
    /// identified by this number.
    public var id: Int?

    /// Create a new `expr` command to send to vim.
    ///
    /// - parameter expression: The `expression` to evaluate.
    /// - parameter id: The `id` of the message. Set this if you want to
    ///   receive a response from Vim.
    public init(_ expression: String, _ id: Int? = nil) {
      self.expression = expression
      self.id = id
    }

    public var json: JSON {
      if let id = self.id {
        return ["expr", expression, id]
      }

      return ["expr", expression]
    }
  }

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
  public struct Call: VimCommandLike {
    public static let kind: VimCommandKind = .call

    /// The `function` to be called
    public var function: String

    /// The arguments to the function
    public var arguments: JSON

    /// An optional message number.  This is nil by default.
    /// If this is set, vim will send a response to the expression command,
    /// identified by this number.
    public var id: Int?

    /// Create a new `expr` command to send to vim.
    ///
    /// - parameter function: The name of the `function` to call.
    /// - parameter args: The arguments to pass to `function`.
    /// - parameter id: The `id` of the message. Set this if you want to
    ///   receive a response from Vim.
    public init(_ function: String, _ args: JSON, _ id: Int? = nil) {
      self.function = function
      self.arguments = args
      self.id = id
    }

    /// Create a new `expr` command to send to vim.
    ///
    /// - parameter function: The name of the `function` to call.
    /// - parameter args: The arguments to pass to `function`.
    /// - parameter id: The `id` of the message. Set this if you want to
    ///   receive a response from Vim.
    public init(function: String, args: JSON, id: Int? = nil) {
      self.init(function, args, id)
    }

    public var json: JSON {
      if let id = self.id {
        return ["call", function, arguments, id]
      }

      return ["call", function, arguments]
    }
  }

  /// Create a redraw command.
  ///
  /// - parameter forced: Whether the `redraw` should be forced.
  /// - returns: a `Redraw` command.
  public static func redraw(_ forced: Bool = false) -> Redraw {
    return Redraw(forced)
  }

  /// Create an ex command.
  ///
  /// - parameter command: The command to execute.
  /// - returns: an `Ex` command.
  public static func ex(_ command: String) -> Ex {
    return Ex(command)
  }

  /// Create a normal-mode command.
  ///
  /// - parameter command: The command to execute.
  /// - returns: a `Normal`-mode command.
  public static func normal(_ command: String) -> Normal {
    return Normal(command)
  }

  /// Create an expression command.
  ///
  /// - parameter expression: The expression to evaluate.
  /// - parameter id: An optional id. If this is set, Vim will send a response.
  /// - returns: an `Expr` command.
  public static func expr(_ expression: String, id: Int? = nil) -> Expr {
    return Expr(expression, id)
  }

  /// Create an function call command.
  ///
  /// - parameter function: The name of the function to call.
  /// - parameter args: A json-compatible array with arguments to the function.
  /// - parameter id: An optional id. If this is set, Vim will send a response.
  /// - returns: a `Call` command.
  public static func call(function: String, args: JSON, id: Int? = nil) -> Call {
    return Call(function: function, args: args, id: id)
  }
}


extension VimCommandLike {
  public func jsonString(using encoding: String.Encoding) -> String? {
    return json.rawString(encoding)
  }

  public func rawData() throws -> Data {
    return try json.rawData()
  }
}
