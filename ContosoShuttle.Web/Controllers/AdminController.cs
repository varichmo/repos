using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using ContosoShuttle.Common;
using ContosoShuttle.Data.Models;
using ContosoShuttle.Data.Repositories;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;
using Microsoft.WindowsAzure.Storage.Queue;
using Microsoft.WindowsAzure.Storage.RetryPolicies;

namespace ContosoShuttle.Web.Controllers
{
    public class AdminController : Controller
    {
        public ActionResult Index()
        {
            ViewBag.Destinations = CreateDestinationsList();

            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> Index(
            Destination? destination,
            HttpPostedFileBase imageFile)
        {
            // A production app would implement more robust input validation.
            // For example, validate that the image file size is not too large.
            try
            {
                if (ModelState.IsValid && destination.HasValue && imageFile != null && imageFile.ContentLength != 0)
                {
                    string url = await UploadAndSaveBlobAsync(destination.Value, imageFile);

                    await UpdateUrl(destination.Value, url);

                    ViewBag.Message = $"{destination} image uploaded successfully";
                }
                else
                {
                    ViewBag.Message = "Please select a destination and image file";
                }
            }
            catch (Exception ex)
            {
                Trace.TraceError($"Error uploading destination image, {ex.Message}");

                ViewBag.Message = "Error uploading destination image, please try again";
            }

            ViewBag.Destinations = CreateDestinationsList();

            return View();
        }

        private SelectList CreateDestinationsList()
        {
            return new SelectList(
                ConfigurationHelper.Destinations.Select(destination => new { Id = destination, Name = destination.ToString() }),
                "Id",
                "Name");
        }

        private async Task UpdateUrl(Destination destination, string url)
        {
            DestinationImageRepository imageRepository = await DestinationImageRepository.Create();

            DestinationImage destinationImage = imageRepository.Find(destination);

            if (destinationImage == null)
            {
                await imageRepository.AddAsync(new DestinationImage
                {
                    Id = Guid.NewGuid(),
                    Destination = destination,
                    ImageURL = url
                });
            }
            else
            {
                destinationImage.ImageURL = url;

                await imageRepository.UpdateAsync(destinationImage);
            }
        }

        private async Task<CloudBlobContainer> CreateCloudBlobContainerAsync()
        {
            string storageConnectionString = await ConfigurationHelper.GetSecret("StorageURI");
            CloudStorageAccount storageAccount = CloudStorageAccount.Parse(storageConnectionString);
            CloudBlobClient blobClient = storageAccount.CreateCloudBlobClient();

            blobClient.DefaultRequestOptions.RetryPolicy = new LinearRetry(TimeSpan.FromSeconds(3), 3);
            CloudBlobContainer blobContainer = blobClient.GetContainerReference("images");
            blobContainer.CreateIfNotExists(BlobContainerPublicAccessType.Off);

            CloudQueueClient queueClient = storageAccount.CreateCloudQueueClient();
            queueClient.DefaultRequestOptions.RetryPolicy = new LinearRetry(TimeSpan.FromSeconds(3), 3);

            return blobContainer;
        }

        private async Task<string> UploadAndSaveBlobAsync(Destination destination, HttpPostedFileBase imageFile)
        {
            CloudBlobContainer blobContainer = await CreateCloudBlobContainerAsync();
            string extension = Path.GetExtension(imageFile.FileName);
            string blobName = destination.ToString();
            CloudBlockBlob imageBlob = blobContainer.GetBlockBlobReference(blobName);

            switch (extension?.ToLower())
            {
                case ".jpg":
                case ".jpeg":
                {
                    imageBlob.Properties.ContentType = "image/jpeg";
                    break;
                }
                case ".png":
                {
                    imageBlob.Properties.ContentType = "image/png";
                    break;
                }
                case ".gif":
                {
                    imageBlob.Properties.ContentType = "image/gif";
                    break;
                }
            }

            using (Stream fileStream = imageFile.InputStream)
            {
                await imageBlob.UploadFromStreamAsync(fileStream);
            }

            return imageBlob.Uri.ToString();
        }
    }
}
