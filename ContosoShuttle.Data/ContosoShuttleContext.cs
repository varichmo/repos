using System;
using System.Collections.Generic;
using System.Data.Entity;
using ContosoShuttle.Common;
using ContosoShuttle.Data.Models;

namespace ContosoShuttle.Data
{
    public class ContosoShuttleContext : DbContext
    {
        public ContosoShuttleContext() : base("ContosoShuttle")
        {
            Database.SetInitializer(new ContosoShuttleInitializer());
        }

        public DbSet<Schedule> Schedules { get; set; }
        public DbSet<DestinationImage> DestinationImages { get; set; }
    }

    public class ContosoShuttleInitializer : CreateDatabaseIfNotExists<ContosoShuttleContext>
    {
        protected override void Seed(ContosoShuttleContext context)
        {
            base.Seed(context);

            List<Schedule> schedules = new List<Schedule>(51);

            for (int i = 6; i < 23; i++)
            {
                TimeSpan timeSpan = TimeSpan.FromHours(i);

                schedules.Add(new Schedule
                {
                    Id = Guid.NewGuid(),
                    Destination = Destination.Kirkland,
                    Stand = "A",
                    DepartureTime = timeSpan,
                    TravelTime = 30
                });

                schedules.Add(new Schedule
                {
                    Id = Guid.NewGuid(),
                    Destination = Destination.Ballard,
                    Stand = "B",
                    DepartureTime = timeSpan.Add(TimeSpan.FromMinutes(20)),
                    TravelTime = 30
                });

                schedules.Add(new Schedule
                {
                    Id = Guid.NewGuid(),
                    Destination = Destination.Everett,
                    Stand = "D",
                    DepartureTime = timeSpan.Add(TimeSpan.FromMinutes(50)),
                    TravelTime = 50
                });

                schedules.Add(new Schedule
                {
                    Id = Guid.NewGuid(),
                    Destination = Destination.Secunderabad,
                    Stand = "A",
                    DepartureTime = timeSpan,
                    TravelTime = 20
                });

                schedules.Add(new Schedule
                {
                    Id = Guid.NewGuid(),
                    Destination = Destination.Pocharam,
                    Stand = "B",
                    DepartureTime = timeSpan.Add(TimeSpan.FromMinutes(15)),
                    TravelTime = 30
                });

                schedules.Add(new Schedule
                {
                    Id = Guid.NewGuid(),
                    Destination = Destination.Nagole,
                    Stand = "D",
                    DepartureTime = timeSpan.Add(TimeSpan.FromMinutes(55)),
                    TravelTime = 60
                });
            }

            context.Schedules.AddRange(schedules);
        }
    }
}
