// Small System.Drawing helper used by the PowerShell build scripts in /tools.
// Crops, resizes and JPEG-encodes resort photography without external dependencies.
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Linq;

public static class ImageKit
{
    static ImageCodecInfo Jpeg = ImageCodecInfo.GetImageEncoders().First(c => c.MimeType == "image/jpeg");

    public static Bitmap Load(string path)
    {
        using (var img = Image.FromFile(path))
            return new Bitmap(img);
    }

    // Crop using fractions of the source (x, y, w, h in 0..1).
    public static Bitmap Crop(Bitmap src, double fx, double fy, double fw, double fh)
    {
        var r = new Rectangle((int)(src.Width * fx), (int)(src.Height * fy),
                              (int)(src.Width * fw), (int)(src.Height * fh));
        return src.Clone(r, PixelFormat.Format32bppArgb);
    }

    public static Bitmap Resize(Image src, int w, int h)
    {
        var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp))
        {
            g.CompositingQuality = CompositingQuality.HighQuality;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            using (var wrap = new ImageAttributes())
            {
                wrap.SetWrapMode(WrapMode.TileFlipXY);
                g.DrawImage(src, new Rectangle(0, 0, w, h), 0, 0, src.Width, src.Height, GraphicsUnit.Pixel, wrap);
            }
        }
        return bmp;
    }

    public static Bitmap ResizeToWidth(Image src, int w)
    {
        int h = (int)Math.Round(src.Height * (double)w / src.Width);
        return Resize(src, w, h);
    }

    // Cover-fit into an exact box (centre weighted by fx/fy focus, 0..1).
    public static Bitmap Cover(Image src, int w, int h, double focusX, double focusY)
    {
        double scale = Math.Max((double)w / src.Width, (double)h / src.Height);
        double sw = w / scale, sh = h / scale;
        double sx = Math.Max(0, Math.Min(src.Width - sw, src.Width * focusX - sw / 2));
        double sy = Math.Max(0, Math.Min(src.Height - sh, src.Height * focusY - sh / 2));
        var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.CompositingQuality = CompositingQuality.HighQuality;
            g.DrawImage(src, new RectangleF(0, 0, w, h), new RectangleF((float)sx, (float)sy, (float)sw, (float)sh), GraphicsUnit.Pixel);
        }
        return bmp;
    }

    public static void SaveJpeg(Image img, string path, long quality)
    {
        // Flatten onto white so no alpha leaks into JPEG.
        using (var flat = new Bitmap(img.Width, img.Height, PixelFormat.Format24bppRgb))
        {
            using (var g = Graphics.FromImage(flat))
            {
                g.Clear(Color.White);
                g.DrawImage(img, 0, 0, img.Width, img.Height);
            }
            var p = new EncoderParameters(1);
            p.Param[0] = new EncoderParameter(Encoder.Quality, quality);
            flat.Save(path, Jpeg, p);
        }
    }

    // Turns the near-white backdrop of the logo transparent by flood-filling from the
    // borders, so interior whites (birds, text highlights) are preserved.
    public static Bitmap RemoveWhiteBackground(Bitmap src, int hard, int soft)
    {
        var bmp = src.Clone(new Rectangle(0, 0, src.Width, src.Height), PixelFormat.Format32bppArgb);
        int W = bmp.Width, H = bmp.Height;
        var data = bmp.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        var px = new byte[W * H * 4];
        System.Runtime.InteropServices.Marshal.Copy(data.Scan0, px, 0, px.Length);
        var seen = new bool[W * H];
        var stack = new System.Collections.Generic.Stack<int>();
        Func<int, int> minC = i => Math.Min(px[i * 4], Math.Min(px[i * 4 + 1], px[i * 4 + 2]));
        for (int x = 0; x < W; x++) { stack.Push(x); stack.Push((H - 1) * W + x); }
        for (int y = 0; y < H; y++) { stack.Push(y * W); stack.Push(y * W + W - 1); }
        while (stack.Count > 0)
        {
            int i = stack.Pop();
            if (seen[i]) continue;
            int m = minC(i);
            if (m < soft) continue;
            seen[i] = true;
            // Pixels brighter than `hard` vanish; between soft..hard fade for a clean edge.
            int a = m >= hard ? 0 : (int)(255.0 * (hard - m) / (hard - soft));
            px[i * 4 + 3] = (byte)Math.Min(px[i * 4 + 3], a);
            int x = i % W, y = i / W;
            if (x > 0) stack.Push(i - 1);
            if (x < W - 1) stack.Push(i + 1);
            if (y > 0) stack.Push(i - W);
            if (y < H - 1) stack.Push(i + W);
        }
        System.Runtime.InteropServices.Marshal.Copy(px, 0, data.Scan0, px.Length);
        bmp.UnlockBits(data);
        return bmp;
    }

    // Builds a single-colour glyph from the dark strokes of a crop (alpha = darkness),
    // used to lift the "J" out of the wordmark for the favicon.
    public static Bitmap MaskFromDark(Bitmap src, int lo, int hi, Color tint)
    {
        var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
        for (int y = 0; y < src.Height; y++)
            for (int x = 0; x < src.Width; x++)
            {
                var c = src.GetPixel(x, y);
                double lum = 0.299 * c.R + 0.587 * c.G + 0.114 * c.B;
                double a = lum <= lo ? 1 : lum >= hi ? 0 : (hi - lum) / (hi - lo);
                bmp.SetPixel(x, y, Color.FromArgb((int)(a * 255 * c.A / 255.0), tint));
            }
        return bmp;
    }

    // Packs PNG frames into a single .ico (PNG-compressed entries, supported by all modern browsers).
    public static void WriteIco(string path, string[] pngPaths)
    {
        var frames = pngPaths.Select(System.IO.File.ReadAllBytes).ToArray();
        using (var fs = new System.IO.FileStream(path, System.IO.FileMode.Create))
        using (var w = new System.IO.BinaryWriter(fs))
        {
            w.Write((short)0); w.Write((short)1); w.Write((short)frames.Length);
            int offset = 6 + 16 * frames.Length;
            for (int k = 0; k < frames.Length; k++)
            {
                int size;
                using (var ms = new System.IO.MemoryStream(frames[k]))
                using (var im = Image.FromStream(ms)) size = im.Width;
                w.Write((byte)(size >= 256 ? 0 : size)); w.Write((byte)(size >= 256 ? 0 : size));
                w.Write((byte)0); w.Write((byte)0);
                w.Write((short)1); w.Write((short)32);
                w.Write(frames[k].Length); w.Write(offset);
                offset += frames[k].Length;
            }
            foreach (var f in frames) w.Write(f);
        }
    }
}
