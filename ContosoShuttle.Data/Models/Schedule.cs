using System;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using ContosoShuttle.Common;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;

namespace ContosoShuttle.Data.Models
{
    public class Schedule
    {
        [Key]
        public Guid Id { get; set; }

        [StringLength(1)]
        public string Stand { get; set; }

        [Range(0, int.MaxValue, ErrorMessage = "TravelTime must be a positive number")]
        [RegularExpression(@"\d+", ErrorMessage = "TravelTime must be a whole number")]
        [DisplayName("Travel Time")]
        public int TravelTime { get; set; }

        [DataType(DataType.Time)]
        [DisplayName("Departs")]
        [DisplayFormat(DataFormatString = "{0:hh\\:mm}", ApplyFormatInEditMode = true)]
        public TimeSpan DepartureTime { get; set; }

        [JsonConverter(typeof(StringEnumConverter))]
        public Destination? Destination { get; set; }
    }
}