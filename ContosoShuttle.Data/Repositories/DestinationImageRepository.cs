using System;
using System.Data.Entity;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using ContosoShuttle.Common;
using ContosoShuttle.Data.Models;

namespace ContosoShuttle.Data.Repositories
{
    public class DestinationImageRepository : IDisposable
    {
        private readonly ContosoShuttleContext _db;

        private DestinationImageRepository(string connectionString)
        {
            _db = new ContosoShuttleContext(connectionString);
        }

        public static async Task<DestinationImageRepository> Create()
        {
            return new DestinationImageRepository(await ConfigurationHelper.GetSecret("SecretURI"));
        }

        public async Task<DestinationImage> FindAsync(Guid id)
        {
            Trace.TraceInformation($"Finding image by id: {id}");

            DestinationImage image = await _db.DestinationImages.FindAsync(id);

            return image;
        }

        public DestinationImage Find(Destination destination)
        {
            Trace.TraceInformation($"Getting image by destination: {destination}");

            return _db.DestinationImages.FirstOrDefault(d => d.Destination == destination);
        }

        public async Task AddAsync(DestinationImage destinationImage)
        {
            Trace.TraceInformation($"Adding image: {destinationImage.Destination}");

            _db.DestinationImages.Add(destinationImage);

            await _db.SaveChangesAsync();
        }

        public async Task UpdateAsync(DestinationImage destinationImage)
        {
            Trace.TraceInformation($"Updating image: {destinationImage.Destination}");

            _db.Entry(destinationImage).State = EntityState.Modified;

            await _db.SaveChangesAsync();
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
