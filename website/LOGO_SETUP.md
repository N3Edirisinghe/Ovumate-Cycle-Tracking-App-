# Logo Setup Instructions

## How to Add Your Logo Image

1. **Save your logo image** as `logo.png` in the `website` folder
   - The image should show a person sleeping on a pillow with "OVUMATE" text
   - File location: `new cycle/website/logo.png`

2. **Image Requirements:**
   - Format: PNG (recommended for transparency) or JPG
   - Recommended size: 400x400px or larger
   - The image will be automatically scaled to fit:
     - Navigation bar: 55x55px
     - Hero section: 220px width (height auto)
     - Footer: 45x45px

3. **File Structure:**
   ```
   website/
   ├── index.html
   ├── style.css
   ├── script.js
   └── logo.png  ← Place your logo image here
   ```

## Logo Display

The logo will automatically appear in:
- **Navigation bar** (top left) - 55x55px
- **Hero section** (center) - 220px width with floating animation
- **Footer** (left side) - 45x45px

## Fallback

If the logo image is not found, a professional fallback icon (🌸) will be displayed instead.

## Testing

1. Save your logo image as `logo.png` in the website folder
2. Open `index.html` in a web browser
3. The logo should appear in all three locations

## Image Optimization Tips

- Use PNG format if your logo has transparency
- Use JPG format for smaller file sizes (if no transparency)
- Optimize the image to reduce file size (recommended: under 200KB)
- Ensure the image is square or close to square for best results

