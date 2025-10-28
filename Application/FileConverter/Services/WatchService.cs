// Copyright (c) AAllard - GPL v3

namespace FileConverter.Services
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using CommunityToolkit.Mvvm.DependencyInjection;
    using FileConverter.ConversionJobs;

    public class WatchService : IDisposable
    {
        private readonly List<FileSystemWatcher> watchers = new List<FileSystemWatcher>();

        private readonly ISettingsService settingsService;
        private readonly IConversionService conversionService;

        public WatchService(ISettingsService settingsService, IConversionService conversionService)
        {
            this.settingsService = settingsService ?? throw new ArgumentNullException(nameof(settingsService));
            this.conversionService = conversionService ?? throw new ArgumentNullException(nameof(conversionService));

            this.RebuildWatchers();
        }

        public void RebuildWatchers()
        {
            foreach (var w in this.watchers)
            {
                try { w.Dispose(); } catch { }
            }
            this.watchers.Clear();

            if (this.settingsService.Settings.WatchFolders == null)
            {
                return;
            }

            foreach (var wf in this.settingsService.Settings.WatchFolders)
            {
                if (string.IsNullOrEmpty(wf.Path) || !Directory.Exists(wf.Path))
                {
                    continue;
                }

                var watcher = new FileSystemWatcher(wf.Path)
                {
                    IncludeSubdirectories = wf.IncludeSubdirectories,
                    EnableRaisingEvents = true,
                    NotifyFilter = NotifyFilters.FileName | NotifyFilters.CreationTime | NotifyFilters.Size
                };

                FileSystemEventHandler handler = (s, e) => this.OnFileCreated(wf.PresetName, e.FullPath);
                watcher.Created += handler;
                watcher.Renamed += (s, e) => this.OnFileCreated(wf.PresetName, e.FullPath);

                this.watchers.Add(watcher);
            }
        }

        private void OnFileCreated(string presetName, string path)
        {
            if (string.IsNullOrEmpty(path) || !File.Exists(path))
            {
                return;
            }

            var preset = this.settingsService.Settings.GetPresetFromName(presetName);
            if (preset == null)
            {
                return;
            }

            try
            {
                var job = ConversionJobFactory.Create(preset, path);
                this.conversionService.RegisterConversionJob(job);
            }
            catch
            {
                // Ignore bad files
            }
        }

        public void Dispose()
        {
            foreach (var w in this.watchers)
            {
                try { w.Dispose(); } catch { }
            }
            this.watchers.Clear();
        }
    }
}
