const fs = require('fs');
const path = require('path');

// Recursive function to find files without external dependencies
function getFiles(dir, allFiles = []) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const name = path.join(dir, file);
        try {
            const stats = fs.statSync(name);
            if (stats.isDirectory()) {
                if (file !== 'node_modules' && file !== 'wp-admin' && file !== 'wp-includes' && file !== '.git') {
                    getFiles(name, allFiles);
                }
            } else {
                if (name.endsWith('.php') || name.endsWith('.html') || name.endsWith('.js') || name.endsWith('.tailwind.json')) {
                    allFiles.push(name);
                }
            }
        } catch (e) {
            // Skip broken symlinks or inaccessible files
            console.warn(`⚠️ Skipping inaccessible file: ${name}`);
        }
    }
    return allFiles;
}

function harvestConfigs() {
    const siteDir = '/var/www/html';
    const scanDir = '/var/www/html/wp-content';
    let mergedTheme = { extend: { colors: {}, fontFamily: {} } };

    try {
        console.log("--> Scanning wp-content for custom tailwind configs...");
        const files = [];
        if (fs.existsSync(scanDir)) {
            getFiles(scanDir, files);
        } else {
            getFiles(siteDir, files);
        }

        files.forEach(file => {
            // Support for standalone .tailwind.json files
            if (file.endsWith('.tailwind.json')) {
                try {
                    const config = JSON.parse(fs.readFileSync(file, 'utf8'));
                    if (config.theme && config.theme.extend) {
                        Object.assign(mergedTheme.extend.colors, config.theme.extend.colors || {});
                        Object.assign(mergedTheme.extend.fontFamily, config.theme.extend.fontFamily || {});
                    }
                } catch (e) {
                    console.warn(`⚠️ Failed to parse JSON config: ${file}`);
                }
                return;
            }

            // Support for embedded tailwind.config = { ... } blocks
            const content = fs.readFileSync(file, 'utf8');
            const regex = /tailwind\.config\s*=\s*({[\s\S]*?})(?=;|\s|$)/g;
            let match;

            while ((match = regex.exec(content)) !== null) {
                try {
                    let configStr = match[1]
                        // Simple cleanup to handle basic JS objects as JSON
                        .replace(/(['"])?([a-zA-Z0-9_]+)(['"])?:/g, '"$2":')
                        .replace(/'/g, '"')
                        .replace(/,\s*}/g, '}')
                        .replace(/,\s*]/g, ']');

                    const config = JSON.parse(configStr);
                    if (config.theme && config.theme.extend) {
                        Object.assign(mergedTheme.extend.colors, config.theme.extend.colors || {});
                        Object.assign(mergedTheme.extend.fontFamily, config.theme.extend.fontFamily || {});
                    }
                } catch (e) { }
            }
        });

        fs.writeFileSync(path.join(siteDir, 'harvested-config.json'), JSON.stringify(mergedTheme, null, 2));
        console.log("✅ Harvested config saved to harvested-config.json");
    } catch (e) {
        console.error("❌ Harvest failed:", e.message);
    }
}

harvestConfigs();
