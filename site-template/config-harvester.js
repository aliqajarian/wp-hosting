const fs = require('fs');
const path = require('path');
const glob = require('glob');

// This script scans the theme/site for inline tailwind.config blocks
// and merges them into a single object for the local compiler.
function harvestConfigs() {
    const siteDir = '/var/www/html';
    const files = glob.sync('**/*.{php,html,js}', {
        cwd: siteDir,
        ignore: ['node_modules/**', 'wp-admin/**', 'wp-includes/**']
    });

    let mergedTheme = { extend: { colors: {}, fontFamily: {} } };

    files.forEach(file => {
        try {
            const content = fs.readFileSync(path.join(siteDir, file), 'utf8');
            // Regex to find tailwind.config = { ... }
            const regex = /tailwind\.config\s*=\s*({[\s\S]*?});/g;
            let match;

            while ((match = regex.exec(content)) !== null) {
                try {
                    // Clean up the JS object string so it's closer to valid JSON or evaluatable
                    let configStr = match[1]
                        .replace(/(['"])?([a-zA-Z0-9_]+)(['"])?:/g, '"$2":') // Quote keys
                        .replace(/'/g, '"') // Swap single quotes
                        .replace(/,\s*}/g, '}') // Fix trailing commas
                        .replace(/,\s*]/g, ']');

                    const config = JSON.parse(configStr);
                    if (config.theme && config.theme.extend) {
                        Object.assign(mergedTheme.extend.colors, config.theme.extend.colors || {});
                        Object.assign(mergedTheme.extend.fontFamily, config.theme.extend.fontFamily || {});
                    }
                } catch (e) {
                    // If parsing fails (common for complex JS), we skip it
                }
            }
        } catch (e) { }
    });

    fs.writeFileSync(path.join(siteDir, 'harvested-config.json'), JSON.stringify(mergedTheme, null, 2));
}

harvestConfigs();
