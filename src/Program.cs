using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Diagnostics.Contracts;
using System.IO;
using Mono.Options;

namespace TimeZoneBuilder
{
    class Program
    {
        static Configuration config = new Configuration();
        static void Main(string[] args)
        {
            var shouldShowHelp = false;
            var options = new OptionSet {
                { "i|input=", "the input folder containing the IANA database files.", i => config.Input = i },
                { "o|output=", "the output file path and name.", o => config.Output = o },
                { "h|help", "show this message and exit", h => shouldShowHelp = h != null },
            };

            List<string> extra;
            try
            {
                extra = options.Parse(args);
            }
            catch (OptionException e)
            {
                // output some error message
                Console.Write("TimeZoneBuilder: ");
                Console.WriteLine(e.Message);
                Console.WriteLine("Try `TimeZoneBuilder --help' for more information.");
                return;
            }

            if (string.IsNullOrEmpty(config.Input))
            {
                Console.Error.WriteLine("Missing required argument `--input=FOLDER`.");
                Console.WriteLine("Try `TimeZoneBuilder --help' for more information.");
                shouldShowHelp = true;

            }
            if (string.IsNullOrEmpty(config.Output))
            {
                Console.Error.WriteLine("Missing required argument `--output=FILE`.");
                Console.WriteLine("Try `TimeZoneBuilder --help' for more information.");
                shouldShowHelp = true;
            }

            if (!Directory.Exists(config.Input))
            {
                Console.Error.WriteLine("Input directory as specified by required argument `--input=FILE` does not exist.");
                Console.WriteLine("Try `TimeZoneBuilder --help' for more information.");
                shouldShowHelp = true;
            }

            if (shouldShowHelp)
            {
                // show some app description message
                Console.WriteLine("Usage: TimeZoneBuilder.exe [OPTIONS]");
                Console.WriteLine();

                // output the options
                Console.WriteLine("Options:");
                options.WriteOptionDescriptions(Console.Out);
                return;
            }

            // fix path with DirectorySeparator separator if need be
            if (!Path.EndsInDirectorySeparator(config.Input))
                config.Input = Path.Combine(config.Input, " ").TrimEnd();

            config.TempFile = Path.GetTempFileName();

            ReadIANAVersion();
            File.Delete(config.Output);
            ReadIANAFiles(config.Input);
            CreateTemplate();
        }

        static public void ReadIANAVersion ()
        {
            var file = Path.Combine(config.Input, "version");
            var version = File.ReadAllText(file);
            config.IANAVersion = version.Trim();
        }

        static public void ReadIANAFiles(string sourceFolder)
        {
            string[] folders = Directory.GetDirectories(sourceFolder);
            foreach (string folder in folders)
            {
                string name = Path.GetFileName(folder);
                ReadIANAFiles(folder);
            }

            string[] files = Directory.GetFiles(sourceFolder);
            foreach (string file in files)
            {
                if (Path.GetFileName(file) != "version")
                {
                    var ziId = file.Remove(0, config.Input.Length).Replace(Path.DirectorySeparatorChar, '/');
                    AddZoneData(file, ziId);
                }
            }

        }

        static void AddZoneData(string fileName, string id)
        {
            var zoneInfoData = File.ReadAllBytes(fileName);
            string zoneInfoDataEncoded = Convert.ToBase64String(zoneInfoData);
            var zoneInfoEntry = $"\t\t{{id: '{id}', data: '{zoneInfoDataEncoded}'}},\n";
            System.IO.File.AppendAllText(config.TempFile, zoneInfoEntry);
        }

        static void CreateTemplate ()
        {
            var template = File.ReadAllText("mono-webassembly-zoneinfo.template");
            var zones = File.ReadAllText(config.TempFile);
            template = template.Replace("$$ZONES$$", zones);
            template = template.Replace("$$IANA_VERSION$$", config.IANAVersion);
            System.IO.File.WriteAllText(config.Output, template);
        }
    }

    public class Configuration
    {
        public string Input { get; set; }
        public string Output { get; set; }
        public string IANAVersion { get; set; }
        public string TempFile { get; set; }

    }
}
