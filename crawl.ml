(*
                         CS 51 Problem Set 5
                   A Web Crawler and Search Engine
                             Spring 2017

The crawler, which builds a dictionary from words to sets of
links.
 *)

(* Rename modules for convenience *)
module WT = Webtypes ;;
module CS = Crawler_services ;;

(* Only look at pagerank if you plan on implementing it! *)
module PR = Pagerank ;;

(*----------------------------------------------------------------------
  Section 1: CRAWLER
 *)

(* TODO: Replace the implementation of the crawl function (currently
   just a stub returning the empty dictionary) with a proper index of
   crawled pages. Build an index as follows:

   Remove a link from the frontier (the set of links that have yet to
   be visited), visit this link, add its outgoing links to the
   frontier, and update the index so that all words on this page are
   mapped to linksets containing this url.

   Keep crawling until we've reached the maximum number of links (n) or
   the frontier is empty.
 *)

let rec crawl (n : int)
          (frontier : WT.LinkSet.set)
          (visited : WT.LinkSet.set)
          (d : WT.LinkIndex.dict)
        : WT.LinkIndex.dict =

  (* auxiliary function to add values to dictionary from list *)
  let rec dict_modify (lst : string list) (dct : WT.LinkIndex.dict) 
        (link : WT.link) : WT.LinkIndex.dict =
        match lst with 
        (* if list of words empty, then nothing is added to dictionary *)
        | [] -> dct
        (* else, add words starting from head *)
        | hd :: tl -> 
          (* update existing list of links *)
          match WT.LinkIndex.lookup dct hd with 
          (* if key not in dictionary then create new key-value pair *)
          | None -> dict_modify tl 
            (WT.LinkIndex.insert dct hd 
              (WT.LinkSet.insert WT.LinkSet.empty link)) link
          (* else update value *)
          | Some v -> dict_modify tl 
            (WT.LinkIndex.insert dct hd (WT.LinkSet.insert v link)) link in

  (* returns elements in set1 but not in set2 *)
  let rec anti_union (set1 : WT.LinkSet.set) (set2 : WT.LinkSet.set)
        : WT.LinkSet.set =
        match WT.LinkSet.choose set2 with
        | None -> set1
        | Some (elt, set) -> 
          anti_union (WT.LinkSet.remove set1 elt) set in

  (* check if we have already crawled n webpages *)
  if n = 0 then d else 

    (* choose a page from the frontier *)
    match (WT.LinkSet.choose frontier) with
    (* if frontier empty then return the dictionary *)
    | None -> d
    | Some (elt, set) ->
      (* check if page already visited *)
      if (WT.LinkSet.member visited elt) then crawl n set visited d
      else 
        (* add page to visited *)
        let new_visited = WT.LinkSet.insert visited elt in 
        (* visit the link *)
        match (CS.get_page elt) with 
        (* if you can't access the page, keep searching the rest of the pages *)
        | None -> crawl n set visited d
        | Some page -> 
          (* add page links to frontier *)
          let temp_frontier = WT.LinkSet.union set page.links in
          (* remove page links if already visited *)
          let new_frontier = anti_union temp_frontier visited in
          (* get the list of words on the page and update dictionary *)
          let new_d = dict_modify page.words d elt in
        crawl (n - 1) new_frontier new_visited new_d ;;

let crawler (num_pages_to_search : int) (initial_link : WT.link) =
  crawl num_pages_to_search
    (WT.LinkSet.singleton initial_link)
    WT.LinkSet.empty
    WT.LinkIndex.empty ;;