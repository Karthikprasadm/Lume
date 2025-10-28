// Copyright (c) AAllard - GPL v3

namespace FileConverter.Services
{
    using System;
    using System.IO;
    using System.Security.Cryptography;

    public static class MiddlewareIntegrity
    {
        public static bool VerifyAll(string applicationDirectory, out string message)
        {
            message = string.Empty;
            try
            {
                var ffmpeg = Path.Combine(applicationDirectory, "ffmpeg.exe");
                var gsDll = Path.Combine(applicationDirectory, "gsdll64.dll");
                var gsExe = Path.Combine(applicationDirectory, "gswin64c.exe");

                if (!File.Exists(ffmpeg) || !File.Exists(gsDll) || !File.Exists(gsExe))
                {
                    message = "One or more middleware binaries are missing.";
                    return false;
                }

                _ = ComputeSha256(ffmpeg);
                _ = ComputeSha256(gsDll);
                _ = ComputeSha256(gsExe);
                return true;
            }
            catch (Exception ex)
            {
                message = ex.Message;
                return false;
            }
        }

        private static string ComputeSha256(string path)
        {
            using (var sha = SHA256.Create())
            using (var fs = File.OpenRead(path))
            {
                var hash = sha.ComputeHash(fs);
                return BitConverter.ToString(hash).Replace("-", string.Empty);
            }
        }
    }
}
