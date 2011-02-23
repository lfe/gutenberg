(defmodule gutenberg
  (import
   (from re (split 2))
   (from string (to_lower 1))
   (from lists (foldl 3) (sort 1) (sort 2) (append 2))
   (rename riak_object ((get_value 1) riak-value))
   (rename dict
           ((new 0) make-dict)
           ((to_list 1) dict->list)
           ((update_counter 3) dict-inc)
           ((from_list 1) list->dict)
           ((fetch_keys 1) dict-keys))
   (rename erlang
           ((binary_to_list 1) bin->list)
           ((list_to_binary 1) list->bin)))
  (export (map_words 3)
          (reduce_word_count 2)))

;; internal funs

(include-file "include/trace.lfe")

(defun words
  ;; takes a binary text string & returns a list of binary [word,1] pairs
  [text]
  (lc [(<- word (split (to_lower (bin->list text)) '"[^a-z]+"))
       (/= #B() word)]
    (list word 1)))

(defun word-inc
  ;; increments the word by count in given dict
  ([[word count] dict]
   (dict-inc word count dict)))

(defun count
  ;; folds the word counts into a list of word, count pairs
  [words]
  (dict->list (foldl (fun word-inc 2) (make-dict) words)))

(defun compare
  ;; compares two word counts (used by sort/2)
  ([[word0 count0] [word1 count1]]
   (or (> count0 count1)
       (and (=:= count0 count1)
            (< word0 word1)))))

(defun lists
  ;; converts [{k,v}] -> [[k,v]]
  [tuples]
  (lc [(<- t tuples)]
    (let [((tuple key value) t)]
      (list key value))))

(defun tuples
  ;; converts [[k,v]] -> [{k,v}]
  [lists]
  (lc [(<- l lists)]
    (let [([key value] l)]
      (tuple key value))))

;; exported funs

(defun map_words
  ;; map over all documents [obj] -> [[word,1]]
  [obj keydata args]
  (words (riak-value obj)))

(defun reduce_word_count
  ;; fold over all word counts [[word,n]] -> [[word,n]]
  [words args]
  (sort (fun compare 2) (lists (count words))))
