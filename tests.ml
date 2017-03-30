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

(* indexing time of crawler *)

let rec timer (n: int) (inc: int) (max: int) (pth: string) : unit =
	let helper n = timer n inc max pth in
		if n < (max + 1) then
			(Printf.printf "n = %d " n;
				ignore (time_crawler crawler n {host = ""; port = 8080; 
				path = pth});
			helper (n + inc))
		else ();;

let simple = 
	Printf.printf "%s\n" "simple-html";
	timer 2 1 8 "./simple-html/index.html" ;;

let html = 
	Printf.printf "%s\n" "html";
	timer 5 1 20 "./html/index.html" ;;

let wiki = 
	Printf.printf "%s\n" "wiki";
	timer 5 5 100 "./wiki/Europe" ;;