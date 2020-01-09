using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using ContosoShuttle.Common;
using ContosoShuttle.Data.Models;


namespace ContosoShuttle.Data.Repositories
{
    public class ScheduleRepository : IDisposable
    {
        private readonly ContosoShuttleContext _db;

        public ScheduleRepository()
        {
            _db = new ContosoShuttleContext();
        }



        public async Task<IList<Schedule>> GetCategoryAsync(Destination? destination, int count)
        {
            Trace.TraceInformation($"Getting schedules by Destination: {destination}");

            IQueryable<Schedule> schedules = _db.Schedules.AsQueryable();

            if (destination != null)
            {
                schedules = schedules.Where(a => a.Destination == destination);
            }

            List<Schedule> list = await schedules
                .OrderBy(a => a.DepartureTime)
                .Take(count)
                .ToListAsync();

            return list;
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        private void Dispose(bool disposing)
        {
            if (disposing)
            {
                if (_db != null)
                {
                    _db.Dispose();
                }
            }
        }
    }
}