const fs = require('fs');
let harvested = { extend: { colors: {}, fontFamily: {} } };
try {
    if (fs.existsSync('./harvested-config.json')) {
        harvested = JSON.parse(fs.readFileSync('./harvested-config.json'));
    }
} catch (e) { }

module.exports = {
    content: [
        './wp-content/**/*.{php,html,js}',
        './*.{php,html,js}',
    ],
    theme: {
        extend: {
            fontFamily: {
                'vazir': ['Vazirmatn', 'ui-sans-serif', 'system-ui', 'sans-serif'],
                'lalezar': ['Lalezar', 'cursive'],
                'yekan': ['YekanBakh', 'sans-serif'],
                ...harvested.extend.fontFamily
            },
            colors: {
                ...harvested.extend.colors
            }
        },
    },
    plugins: [],
}
