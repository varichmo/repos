using System.Collections.Generic;
using System.ComponentModel;
using System.Threading.Tasks;
using Microsoft.Azure;
using Microsoft.Azure.KeyVault;
using Microsoft.Azure.KeyVault.Models;




namespace ContosoShuttle.Common
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
                string environment = GetConfigValue("Environment");

                return environment == "App Service (Asia)"
                    ? new List<Destination> { Destination.Secunderabad, Destination.Pocharam, Destination.Nagole }
                    : new List<Destination> { Destination.Ballard, Destination.Everett, Destination.Kirkland };
            }
        }

        public static async Task<string> GetSecret(string key)
        {
            KeyVaultClient client = new KeyVaultClient(TokenHelper.GetToken);
            SecretBundle secret = await client.GetSecretAsync(ConfigurationHelper.GetConfigValue(key));

            return secret.Value;
        }

    }
}