(*
                         CS 51 Problem Set 5
                   A Web Crawler and Search Engine
                             Spring 2017

Code for the page-rank algorithm, including a dummy indegree algorithm
for computing page ranks.
 *)

module WT = Webtypes ;;
module NS = Nodescore ;;
module G = Graph ;;
module MS = Myset ;;

open WT ;;

(* Dictionaries mapping links to their ranks. Higher is better. *)
module RankDict =
  Dict.Make (struct
    type key = link
    type value = float
    let compare = link_compare
    let string_of_key = string_of_link
    let string_of_value = string_of_float
    let gen_key () = { host = ""; port = 0; path = "" }
    let gen_key_gt _ = gen_key ()
    let gen_key_lt _ = gen_key ()
    let gen_key_random () = gen_key ()
    let gen_key_between _ _ = None
    let gen_value () = 0.0
    let gen_pair () = (gen_key (), gen_value ())
  end)

module PageSet =
  MS.Make (struct
    type t = page
    let compare = (fun a b -> link_compare a.url b.url)
    let string_of_t = string_of_page
    let gen () =
      let inital_link = {host = ""; port = 0; path = ""} in
      {url = inital_link; links = LinkSet.empty; words = []}
    let gen_lt _ = gen ()
    let gen_gt _ = gen ()
    let gen_random () = gen ()
    let gen_between _ _ = None
  end)

module PageGraph =
  G.Graph (struct
    type node = link
    let compare = link_compare
    let string_of_node = string_of_link
    let gen () = {host=""; port=0; path=""}
  end)

module PageScore = 
  NS.NodeScore (struct
    type node = link
    let string_of_node = string_of_link
    let compare = link_compare
    let gen () = {host=""; port=0; path=""}
  end)

(* Given a bunch of pages, convert them to a graph *)
let graph_of_pages (pages : PageSet.set) : PageGraph.graph =
  (* Only want graph nodes for pages we actually crawled *)
  let crawled_links =
    PageSet.fold (fun s page -> LinkSet.insert s page.url)
      LinkSet.empty pages
  in
  let add_links page graph =
    let add_link g dst =
      if LinkSet.member crawled_links dst then
        PageGraph.add_edge g page.url dst
      else g
    in
      LinkSet.fold add_link graph page.links
  in
  PageSet.fold (fun graph page -> add_links page graph)
         PageGraph.empty pages

(* The rest of the world wants a RankDict, not a NodeScore. *)

let dict_of_ns (ns : PageScore.node_score_map) : RankDict.dict =
  PageScore.fold RankDict.insert RankDict.empty ns

(* A type for modules that can compute nodescores from graphs *)
module type RANKER =
sig
  module G: G.GRAPH
  module NS: NS.NODE_SCORE
  val rank : G.graph -> NS.node_score_map
end


(* Each node's rank is equal to the number of pages that link to it. *)
module InDegreeRanker  (GA: G.GRAPH) (NSA: NS.NODE_SCORE with module N = GA.N) :
    (RANKER with module G = GA with module NS = NSA) =
  struct
    module G = GA
    module NS = NSA

    let rank (g : G.graph) =
      let add_node_edges ns node =
        let neighbors = match G.neighbors g node with
          | None -> []
          | Some xs -> xs
        in
        List.fold_left (fun ns' neighbor -> NS.add_score ns' neighbor 1.0) ns neighbors
      in
      let nodes = G.nodes g in
      List.fold_left add_node_edges (NS.zero_node_score_map nodes) nodes
  end



(*****************************************************************)
(* CHALLENGE PROBLEM:   Random Walk Ranker                       *)
(*****************************************************************)

module type WALK_PARAMS =
sig
  (* Should we randomly jump somewhere else occasionally?
    if no, this should be None.  Else it should be the probability of
    jumping on each step *)
  val do_random_jumps : float option
  (* How far must sisyphus walk? *)
  val num_steps : int
end

module RandomWalkRanker (GA: G.GRAPH) 
                        (NSA: NS.NODE_SCORE with module N = GA.N)
                        (P : WALK_PARAMS)
                      : (RANKER with module G = GA with module NS = NSA) =
struct
  module G = GA
  module NS = NSA

  (* TODO - fill this in*)
  let rank = failwith "Not Implemented"
end




(*****************************************************************)
(* CHALLENGE PROBLEM:   Random Walk Ranker                       *)
(*****************************************************************)

(* 
module type QUANTUM_PARAMS =
sig
  (* What fraction of each node's score should be uniformly distributed
     to the graph as a whole? *)
  val alpha : float
  (* How many rounds? *)
  val num_steps : int

  (* Print stuff? *)
  val debug : bool
end

module QuantumRanker (GA: GRAPH) (NSA: NODE_SCORE with module N = GA.N)
  (P : QUANTUM_PARAMS) :
  (RANKER with module G = GA with module NS = NSA) =
struct
  module G = GA
  module NS = NSA

    (* TODO - fill this in *)

*) 


(*******************  TESTS BELOW  *******************)

module TestInDegreeRanker =
struct
  module G = G.NamedGraph
  let g = G.add_edge G.empty "a" "b";;
  let g2 = G.add_edge g "a" "c";;

  module NS = NS.NodeScore (struct
                           type node = string
                           let compare = Order.string_compare
                           let string_of_node = fun x -> x
                           let gen () = ""
                         end);;

  module Ranker = InDegreeRanker (G) (NS);;
  let ns = Ranker.rank g2;;
  (* let _ = Printf.printf "NS: %s\n" (NS.string_of_node_score_map ns) ;; *)
  assert ((NS.get_score ns "a") = Some 0.0);;
  assert ((NS.get_score ns "b") = Some 1.0);;
  assert ((NS.get_score ns "c") = Some 1.0);;
  assert ((NS.get_score ns "d") = None);;

  let g3 = G.add_edge g2 "b" "c";;
  let ns2 = Ranker.rank g3;;
  assert ((NS.get_score ns2 "a") = Some 0.0);;
  assert ((NS.get_score ns2 "b") = Some 1.0);;
  assert ((NS.get_score ns2 "c") = Some 2.0);;

end


module TestRandomWalkRanker =
struct
  module G = G.NamedGraph
  let g = G.from_edges [("a","b") ;
                        ("b","c") ;
                        ("c","d") ;
                        ("d","e") ;
                        ("e","f") ;
                        ("a","g") ;
                        ("g","a")]

  module NS = NS.NodeScore (struct
                           type node = string
                           let compare = Order.string_compare
                           let string_of_node = fun x -> x
                           let gen () = ""
                         end);;

  (* Uncomment this to test!
  module Ranker = RandomWalkRanker (G) (NS)
    (struct
       let do_random_jumps = None
       let num_steps = 1000
     end)

  let ns = Ranker.rank g
  let _ = Printf.printf "Testing RandomWalkRanker:\n NS: %s\n"
    (NS.string_of_node_score_map ns)
  *)
(* That's the problem with randomness -- hard to test *)
end


module TestQuantumRanker =
struct
  module G = G.NamedGraph
  let g = G.from_edges [("a","b") ;
                        ("a","c") ;
                        ("b","c") ;
                        ("c","a")]

  module NS = NS.NodeScore (struct
                           type node = string
                           let compare = Order.string_compare
                           let string_of_node = fun x -> x
                           let gen () = ""
                         end);;
  (* Uncomment this to test! 
  module Ranker = QuantumRanker (G) (NS)
    (struct
       let alpha = 0.01
       let num_steps = 1
       let debug = true
     end)
  
  let ns = Ranker.rank g
  let _ = Printf.printf "Testing Quantum ranker:\n %s\n"
    (NS.string_of_node_score_map ns)
  *) 

(* That's the problem with randomness -- hard to test *)
end

(* change this to change which ranker we use! *)
module EngineRanker = InDegreeRanker (PageGraph) (PageScore)

  (*
     = PR.RandomWalkRanker (PR.PageGraph) (PR.PageScore) (struct
       let do_random_jumps = Some 0.20
       let num_steps = 1000
     end)
  *)

   (*= PR.QuantumRanker (PR.PageGraph) (PR.PageScore) (struct
       let alpha = 0.01
       let num_steps = 1
       let debug = true
     end)*)
