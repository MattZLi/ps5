(* 
                         CS 51 Problem Set 5
                   A Web Crawler and Search Engine
                             Spring 2017

Part 3 of the pset: tests performance of the implementations.

 *)

 open Askshiebs_tests ;;
 open Crawl ;;
 
 (*----------------------------------------------------------------------
  Compare times
 *)

(* initialize both implementations of crawlers *)

let list_crawler = 

let dict_crawler = crawl

(* compare indexing time of crawler *)

time_crawler list_crawler 8 simple-html/index

time_crawler dict_crawler 8 simple-html/index

time_crawler list_crawler 20 html/index

time_crawler dict_crawler 20 html/index

time_crawler list_crawler 224 wiki/Europe

time_crawler dict_crawler 224 wiki/Europe

(* compare searching time for each implementation *)
(* different queries
using AND and OR *)


