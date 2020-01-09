using System.Collections.Generic;
using System.ComponentModel;
using ContosoShuttle.Data.Models;
using Microsoft.Azure;

namespace ContosoShuttle.Data
{
    public static class ConfigurationHelper
    {
        public static string GetConfigValue(string key)
        {
            var value = CloudConfigurationManager.GetSetting(key);
            return value;
        }

        public static T GetConfigValue<T>(string key)
        {
            var value = GetConfigValue(key);
            var tValue = (T)TypeDescriptor.GetConverter(typeof(T)).ConvertFromString(value);
            return tValue;
        }

        public static IList<Destination> Destinations
        {
            get
            {
                return IsCloudService()
                    ? new List<Destination> { Destination.Secunderabad, Destination.Pocharam, Destination.Nagole }
                    : new List<Destination> { Destination.Ballard, Destination.Everett, Destination.Kirkland };
            }
        }

        public static bool IsCloudService()
        {
            string environment = GetConfigValue("Environment");

            return environment == "Cloud Service" || environment == "Local Cloud Service";
        }
    }
}