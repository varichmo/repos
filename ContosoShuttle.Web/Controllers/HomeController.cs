using System.Web.Mvc;
using ContosoShuttle.Common;
using ContosoShuttle.Data;
using ContosoShuttle.Web.Helpers;

namespace ContosoShuttle.Web.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            ViewBag.Destinations = ConfigurationHelper.Destinations;

            return View();
        }
    }
}