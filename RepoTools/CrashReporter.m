//
//  CrashReporter.m
//  PodToBUILD
//
//  Created by Jerry Marino on 4/25/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

#import "CrashReporter.h"
#import <signal.h>
#import <execinfo.h>

@implementation CrashReporter


void sigHandler(int signal)
{
   NSLog(@"Received signal: %zd", signal);
   void* callstack[128];
   int frames = backtrace(callstack, 128);
   NSString *crashLogFilePath = @"/tmp/repo_tools_log.txt";
   const char* fileNameCString = [crashLogFilePath cStringUsingEncoding:NSUTF8StringEncoding];
   FILE* crashFile = fopen(fileNameCString, "w");
   short crashLogFileDescriptor = crashFile->_file;
   backtrace_symbols_fd(callstack, frames, crashLogFileDescriptor);
   exit(signal);
}

- (id)init
{
   if (self = [super init]) {
      // All of the signals
      signal(SIGXFSZ, sigHandler);
      signal(SIGXCPU, sigHandler);
      signal(SIGALRM, sigHandler);
      signal(SIGPIPE, sigHandler);
      signal(SIGSYS, sigHandler);
      signal(SIGSEGV, sigHandler);
      signal(SIGBUS, sigHandler);
      signal(SIGFPE, sigHandler);
      signal(SIGEMT, sigHandler);
      signal(SIGABRT, sigHandler);
      signal(SIGTRAP, sigHandler);
      signal(SIGILL, sigHandler);
      signal(SIGQUIT, sigHandler);
   }
   return self;
}

@end
