// Signal.swift - A "Swifty" Enum for Unix Signals
//
// This source file is part of the VimChannelKit open source project
//
// Copyright (c) 2014 - 2016
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// -----------------------------------------------------------------------------
///
/// This file contains a "Swifty" Enum for Unix Signals
///
// -----------------------------------------------------------------------------

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
  import Darwin.C
#elseif os(Linux) || os(FreeBSD) || os(Android) || os(PS4)
  import Glibc
#endif

/// Represents a Unix Signal
public enum Signal {
  /// hangup
  case hup
  /// interrupt
  case int
  /// quit
  case quit
  /// illegal instruction (not reset when caught)
  case ill
  /// trace trap (not reset when caught)
  case trap
  /// abort()
  case abrt
  /// floating point exception
  case fpe
  /// kill (cannot be caught or ignored)
  case kill
  /// bus error
  case bus
  /// segmentation violation
  case segv
  /// bad argument to system call
  case sys
  /// write on a pipe with no one to read it
  case pipe
  /// alarm clock
  case alrm
  /// software termination signal from kill
  case term
  /// urgent condition on IO channel
  case urg
  /// sendable stop signal not from tty
  case stop
  /// stop signal from tty
  case tstp
  /// continue a stopped process
  case cont
  /// to parent on child stop or exit
  case chld
  /// to readers pgrp upon background tty read
  case ttin
  /// like TTIN for output if (tp->t_local&LTOSTOP)
  case ttou
  /// exceeded CPU time limit
  case xcpu
  /// exceeded file size limit
  case xfsz
  /// virtual time alarm
  case vtalrm
  /// profiling time alarm
  case prof
  /// user-defined signal 1
  case usr1
  /// user-defined signal 2
  case usr2

  /// Returns the raw Int32 value of the signal
  public var rawValue: Int32 {
    switch self {
    case .hup:    return SIGHUP
    case .int:    return SIGINT
    case .quit:   return SIGQUIT
    case .ill:    return SIGILL
    case .trap:   return SIGTRAP
    case .abrt:   return SIGABRT
    case .fpe:    return SIGFPE
    case .kill:   return SIGKILL
    case .bus:    return SIGBUS
    case .segv:   return SIGSEGV
    case .sys:    return SIGSYS
    case .pipe:   return SIGPIPE
    case .alrm:   return SIGALRM
    case .term:   return SIGTERM
    case .urg:    return SIGURG
    case .stop:   return SIGSTOP
    case .tstp:   return SIGTSTP
    case .cont:   return SIGCONT
    case .chld:   return SIGCHLD
    case .ttin:   return SIGTTIN
    case .ttou:   return SIGTTOU
    case .xcpu:   return SIGXCPU
    case .xfsz:   return SIGXFSZ
    case .vtalrm: return SIGVTALRM
    case .prof:   return SIGPROF
    case .usr1:   return SIGUSR1
    case .usr2:   return SIGUSR2
    }
  }
}

extension Signal: RawRepresentable {
  /// Initialize with a raw Int32 value
  public init?(rawValue: Int32) {
    switch rawValue {
    case SIGHUP:    self = .hup
    case SIGINT:    self = .int
    case SIGQUIT:   self = .quit
    case SIGILL:    self = .ill
    case SIGTRAP:   self = .trap
    case SIGABRT:   self = .abrt
    case SIGFPE:    self = .fpe
    case SIGKILL:   self = .kill
    case SIGBUS:    self = .bus
    case SIGSEGV:   self = .segv
    case SIGSYS:    self = .sys
    case SIGPIPE:   self = .pipe
    case SIGALRM:   self = .alrm
    case SIGTERM:   self = .term
    case SIGURG:    self = .urg
    case SIGSTOP:   self = .stop
    case SIGTSTP:   self = .tstp
    case SIGCONT:   self = .cont
    case SIGCHLD:   self = .chld
    case SIGTTIN:   self = .ttin
    case SIGTTOU:   self = .ttou
    case SIGXCPU:   self = .xcpu
    case SIGXFSZ:   self = .xfsz
    case SIGVTALRM: self = .vtalrm
    case SIGPROF:   self = .prof
    case SIGUSR1:   self = .usr1
    case SIGUSR2:   self = .usr2
    default:        return nil
    }
  }
}
