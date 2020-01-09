using System;
using System.Threading.Tasks;
using System.Web.Mvc;
using ContosoShuttle.Common;
using ContosoShuttle.Data;
using ContosoShuttle.Web.Helpers;

namespace ContosoShuttle.Web.Controllers
{
    public class ErrorsController : Controller
    {
        public ActionResult Index()
        {
            ViewBag.IsPegged = CpuHelper.IsPegged;
            ViewBag.CpuLevel = ConfigurationHelper.GetConfigValue<double>("ErrorsPegCPULevel");
            ViewBag.PegTime = ConfigurationHelper.GetConfigValue<TimeSpan>("ErrorsPegCPUTimeSpan");
            return View();
        }

        public ActionResult PegCpu()
        {
            var cpuLevel = ConfigurationHelper.GetConfigValue<double>("ErrorsPegCPULevel");
            var pegTime = ConfigurationHelper.GetConfigValue<TimeSpan>("ErrorsPegCPUTimeSpan");
            Task.Run(() => { CpuHelper.PegCpu(cpuLevel, pegTime); });
            return RedirectToAction("Index");
        }

        public ActionResult UnpegCpu()
        {
            Task.Run(() => { CpuHelper.UnPegCpu(); });
            return RedirectToAction("Index");
        }
    }
}