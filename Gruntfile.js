module.exports = function(grunt) {

  grunt.initConfig({
    watch: {
      // Watch some livescripts
      bot: {files: ['**/*.ls'], tasks: ['livescript:main']}
    },
    livescript: {
      main: {
        options: {bare: true},
        expand: true,
        cwd: 'src',
        src: ['**/*.ls'],
        dest: 'js/',
        ext: '.js'
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-livescript');

  grunt.registerTask('default', ['livescript']);
  grunt.registerTask('dev', ['livescript', 'watch']);
};
