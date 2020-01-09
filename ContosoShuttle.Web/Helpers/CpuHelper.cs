using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;

namespace ContosoShuttle.Web.Helpers
{
    public class CpuHelper
    {
        /// <summary>
        /// 0 = Idle
        /// 1 = Peg CPU Running
        /// </summary>
        private static int _state;

        public static bool IsPegged => _state == 1;

        /// <summary>
        /// Create artificial load on the CPU at level percent for length time
        /// Can only be called once at a time, any further calls will be ignored until the
        /// currently running time has elapsed
        /// </summary>
        /// <param name="level"></param>
        /// <param name="length"></param>
        public static void PegCpu(double level, TimeSpan length)
        {
            var oldState = Interlocked.CompareExchange(ref _state, 1, 0);
            if (oldState == 0)
            {
                try
                {
                    Trace.TraceInformation($"ProcessQueueMessage Peg CPU to {level} for {length.TotalSeconds} seconds");
                    var threads = new List<Thread>();
                    for (var i = 0; i < Environment.ProcessorCount; i++)
                    {
                        var thread = new Thread(cpu =>
                        {
                            const int iterationTime = 100;
                            var runTime = (int)((double)cpu * iterationTime);
                            var sleepTime = TimeSpan.FromMilliseconds(iterationTime - runTime);

                            var stopwatch = Stopwatch.StartNew();
                            while (_state == 1)
                            {
                                if (stopwatch.ElapsedMilliseconds > runTime)
                                {
                                    Thread.Sleep(sleepTime);
                                    stopwatch.Restart();
                                }
                            }
                        });
                        thread.Start(level);
                        threads.Add(thread);
                    }
                    Thread.Sleep(length);
                    foreach (var thread in threads)
                    {
                        thread.Abort();
                    }
                }
                finally
                {
                    _state = 0;
                }
            }
        }

        /// <summary>
        /// Stop any currently running cpu peg operations
        /// </summary>
        public static void UnPegCpu()
        {
            _state = 0;
        }
    }
}
