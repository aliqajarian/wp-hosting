# 🛠️ Site Admin & Developer Guide

This guide is for **Site Administrators** and **Theme Developers**.
It explains how to access your database and how to use the pre-installed frontend tools (Tailwind, Icons, Fonts) to build your site faster.

---

## 🗄️ 1. accessing Your Database (phpMyAdmin)

We use a single, central **phpMyAdmin** dashboard for all sites.

**📍 URL:** `http://pma.yourdomain.com` (Ask your server admin for the link)

### How to Log In
When you open phpMyAdmin, you will see a login screen. You must fill it out exactly like this:

| Field | What to Type | Example |
| :--- | :--- | :--- |
| **Server** | **Your Database Container Name** | `client1_db` |
| **Username** | Your Database Username | `client1_user` |
| **Password** | Your Database Password | `(your secret password)` |

> **⚠️ Important:** Never use `localhost` or `127.0.0.1` for the Server field. You MUST use the container name (e.g., if your site folder is `myshop`, the server is `myshop_db`).

---

## 🎨 2. Using TailwindCSS (Automatic)

You **do not** need to install Node.js or run `npm run watch`. The server does this for you automatically.

*   **Where to edit:** `wp-content/themes/your-theme/style.css` (or any `.php` file).
*   **Where is the output?** The system automatically compiles your changes into `output.css`.
*   **How to check:**
    1.  Add a standard Tailwind class like `<h1 class="text-3xl text-red-500">` to a PHP file.
    2.  Refresh your browser. It should work instantly.

**Configuration:**
If you need to change colors or fonts, edit `tailwind.config.js` inside your theme folder.

---

## 🌟 3. Using Icons (Lucide)

We have the **Lucide** icon set pre-installed. The best way to use it in WordPress is via an "SVG Sprite".

### Step 1: get the Sprite File
You need to copy the sprite file into your theme folder one time.
Ask your server admin to run this, or do it via the File Manager/Shell:

```bash
# Command to run inside your site's BUILDER container:
cp /app/node_modules/lucide/dist/lucide-sprite.svg /app/
```

### Step 2: Display an Icon
Once the file `lucide-sprite.svg` is in your theme folder, use this HTML in your PHP files:

```php
<!-- Example: Camera Icon -->
<svg class="w-6 h-6 text-gray-700">
    <use href="<?php echo get_template_directory_uri(); ?>/lucide-sprite.svg#camera" />
</svg>
```
*Replace `#camera` with any icon name from [lucide.dev](https://lucide.dev/icons).*

---

## 🔤 4. Using Local Google Fonts (Vazirmatn, Roboto...)

To make your site faster and avoid CDN blocking, we host fonts locally.

1.  **Check your theme:** Look for a `fonts` folder in your theme directory.
2.  **Check your CSS:** Open your `style.css` (or `input.css`).
3.  **Import:** Ensure this line is at the very top:

```css
@import "./fonts/fonts.css";
```

**How to add a new font?**
You cannot just paste a Google Fonts URL. You must ask the **Server Admin** to run the "Localizer Tool" for you. They will generate the files and place them in your `fonts` folder.

---

## ❓ FAQ

**Q: Can I install my own npm packages?**
A: No, the `node_modules` folder is read-only and shared across all sites to save space. Use the tools provided (Tailwind, Lucide).

**Q: My CSS isn't updating!**
A:
1.  Hard refresh your browser (`Ctrl + F5`).
2.  Check if you accidentally deleted `tailwind.config.js`.
3.  Ask admin to restart the `builder` container.
