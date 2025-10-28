// <copyright file="MainWindow.xaml.cs" company="AAllard">License: http://www.gnu.org/licenses/gpl.html GPL version 3.</copyright>

namespace FileConverter.Views
{
    using System.Windows;
    using System.Linq;
    using FileConverter.ViewModels;
    using FileConverter.ConversionJobs;
    using CommunityToolkit.Mvvm.DependencyInjection;
    using FileConverter.Services;

    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            this.InitializeComponent();

            // Enable drag and drop enqueue
            this.PreviewDragOver += (s, e) =>
            {
                if (e.Data != null && e.Data.GetDataPresent(DataFormats.FileDrop))
                {
                    e.Effects = DragDropEffects.Copy;
                    e.Handled = true;
                }
            };

            this.Drop += (s, e) =>
            {
                if (!e.Data.GetDataPresent(DataFormats.FileDrop))
                {
                    return;
                }

                var files = (string[])e.Data.GetData(DataFormats.FileDrop);
                if (files == null || files.Length == 0)
                {
                    return;
                }

                var vm = this.DataContext as MainViewModel;
                var settingsService = Ioc.Default.GetRequiredService<ISettingsService>();
                var conversionService = Ioc.Default.GetRequiredService<IConversionService>();

                // Use last-used preset if available, fallback to first
                var defaultPreset = settingsService.Settings.GetPresetFromName(settingsService.Settings.LastUsedPresetName)
                    ?? settingsService.Settings.ConversionPresets.FirstOrDefault();
                if (defaultPreset == null)
                {
                    return;
                }

                foreach (var path in files)
                {
                    var job = ConversionJobFactory.Create(defaultPreset, path);
                    conversionService.RegisterConversionJob(job);
                }

                // Remember last used preset
                settingsService.Settings.LastUsedPresetName = defaultPreset.FullName;
                settingsService.SaveSettings();
            };
        }
    }
}
