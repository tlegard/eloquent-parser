module.exports = function(grunt) {

  grunt.initConfig({
    watch: {
      // Watch some livescripts
      bot: {files: ['**'], tasks: ['livescript:main', 'shell:create']},
      options: {
        livereload: true
      }
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
    },
    shell: {
      create: {
        command: 'node js/test.js',
        options: {
          stdout: true,
          stderr: true
        }
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-livescript');
  grunt.loadNpmTasks('grunt-shell');


  grunt.registerTask('default', ['livescript']);
  grunt.registerTask('dev', ['livescript', 'watch']);
};
