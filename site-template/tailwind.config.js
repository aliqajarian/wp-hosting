module.exports = {
    content: [
        './wp-content/themes/**/*.php',
        './wp-content/themes/**/*.html',
        './wp-content/themes/**/*.js',
    ],
    theme: {
        extend: {
            fontFamily: {
                'vazir': ['Vazirmatn', 'ui-sans-serif', 'system-ui', 'sans-serif'],
                'lalezar': ['Lalezar', 'cursive'],
                'yekan': ['YekanBakh', 'sans-serif'],
            },
        },
    },
    plugins: [],
}
