# Logo Setup Instructions

## How to Add the Logo Image

1. **Save your logo image** as `logo.png` in the `website` folder
   - The image should be in PNG format
   - Recommended size: 200x200px or larger (will be scaled automatically)
   - Transparent background is preferred

2. **File location:**
   ```
   website/
   ├── index.html
   ├── style.css
   ├── script.js
   └── logo.png  ← Place your logo here
   ```

3. **Alternative formats:**
   If your logo is in a different format (JPG, SVG, etc.), you can:
   - Rename it to `logo.png` (if it's already PNG)
   - Or update the HTML files to use your file name:
     - Change `logo.png` to `logo.jpg` (or your file name)
     - In `index.html`, find all instances of `src="logo.png"` and change to your file name

## Logo Placement

The logo appears in three places:
1. **Navigation bar** - Top left (50x50px)
2. **Hero section** - Center of hero section (200px width)
3. **Footer** - Footer section (40x40px)

## Image Optimization Tips

- Use PNG format for transparent backgrounds
- Use JPG format for smaller file sizes (if no transparency needed)
- Optimize the image to reduce file size (use tools like TinyPNG)
- Recommended dimensions: 400x400px or larger (will scale down automatically)

## If You Don't Have the Logo Yet

The website will still work, but you'll see broken image icons. You can:
1. Use a placeholder service: `https://via.placeholder.com/200`
2. Or temporarily use an emoji by reverting the changes

## Testing

After adding the logo:
1. Open `index.html` in a web browser
2. Check that the logo appears in:
   - Navigation bar (top left)
   - Hero section (center)
   - Footer (left side)

