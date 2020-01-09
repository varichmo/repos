using System;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using ContosoShuttle.Common;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;

namespace ContosoShuttle.Data.Models
{
    public class DestinationImage
    {
        [Key]
        public Guid Id { get; set; }

        [JsonConverter(typeof(StringEnumConverter))]
        public Destination? Destination { get; set; }

        [StringLength(2083)]
        [DisplayName("Image")]
        public string ImageURL { get; set; }
    }
}
