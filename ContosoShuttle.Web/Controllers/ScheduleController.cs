using System.Collections.Generic;
using System.Threading.Tasks;
using System.Web.Mvc;
using ContosoShuttle.Common;
using ContosoShuttle.Data.Models;
using ContosoShuttle.Data.Repositories;

namespace ContosoShuttle.Web.Controllers
{
    [HandleError]
    public class ScheduleController : Controller
    {
        public async Task<ActionResult> Index(Destination? destination, int count = 50)
        {
            if (destination.HasValue)
            {
                DestinationImageRepository imageRepository = await DestinationImageRepository.Create();

                DestinationImage destinationImage = imageRepository.Find(destination.Value);

                ViewBag.Title = $"{destination} Schedule";
                ViewBag.ImageUrl = destinationImage?.ImageURL;

                string SAStoken = ConfigurationHelper.GetConfigValue("SAStoken");
                if ((ViewBag.ImageUrl) != null) ViewBag.ImageUrl += SAStoken;
            }
            else
            {
                ViewBag.Title = "All Schedules";
                ViewBag.ImageUrl = null;
            }

            ScheduleRepository scheduleRepository = new ScheduleRepository();

            IList<Schedule> schedules = await scheduleRepository.GetCategoryAsync(destination, count);

            return View(schedules);
        }
    }
}
