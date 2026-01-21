module.exports = {
    content: [
      './app/views/**/*.{erb,html,html.erb}',
      './app/helpers/**/*.rb',
      './app/builders/**/*.rb',
      './app/assets/stylesheets/**/*.css',
      './app/javascript/**/*.js',
      './app/components/**/*.{erb,html,html.erb}'
    ],
    plugins: [
      require('@tailwindcss/forms'),
    ],
  }