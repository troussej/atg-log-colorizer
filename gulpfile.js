"use strict";
const gulp = require("gulp");
const del = require("del");
const ts = require('gulp-typescript');
const runSequence = require("run-sequence");
const tsProject = ts.createProject('tsconfig.json');
var pegjs = require('gulp-pegjs');

const _ = require('lodash');

const rename = require("gulp-rename");
const chmod = require('gulp-chmod');

const targetFolder = 'dist';


gulp.task("clean", function(done) {
    return del([targetFolder], done);
});

gulp.task('scripts', function() {


    var tsResult = tsProject.src()
        .pipe(tsProject());


    return tsResult.js.pipe(gulp.dest(targetFolder));
});

gulp.task('parser',function(){

     return gulp.src('src/parser/*.pegjs')
        .pipe(pegjs({format: "commonjs"}))
        .pipe(gulp.dest('dist/parser/'));
   
})



gulp.task("watch", function() {
    runSequence("clean", "scripts");
    gulp.watch(["./src"], ["scripts"]);
});

gulp.task("default", function(done) {
    runSequence("clean", "scripts", "parser",  done);
});