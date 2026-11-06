#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct Node { char word[16]; int count; struct Node *left, *right; } Node;
Node *insert(Node *n, const char *word) {  // smaller to the left, bigger to the right
    if (n == NULL) {  // empty spot found: the new node goes here
        if (!(n = calloc(1, sizeof *n))) exit(EXIT_FAILURE);  // count 0, children NULL
        snprintf(n->word, sizeof n->word, "%s", word);
    }
    int cmp = strcmp(word, n->word);
    if (cmp < 0) n->left = insert(n->left, word);
    else if (cmp > 0) n->right = insert(n->right, word);
    else n->count++;  // the word is here: new (0 -> 1) or repeated
    return n;
}
const Node *find(const Node *n, const char *word) {  // one branch per level
    while (n && strcmp(word, n->word) != 0) n = strcmp(word, n->word) < 0 ? n->left : n->right;
    return n;
}
void in_order(const Node *n) {  // left, node, right: alphabetical order
    if (n) { in_order(n->left); printf("  %-6s x%d\n", n->word, n->count); in_order(n->right); }
}
void free_tree(Node *n) { if (n) { free_tree(n->left); free_tree(n->right); free(n); } }
int main(void) {
    const char *words[] = {"melon", "fig", "pear", "apple", "kiwi", "fig", "plum", "apple", "fig"};
    Node *root = NULL;  // an empty tree
    for (int i = 0; i < 9; i++) root = insert(root, words[i]);
    in_order(root);
    printf("Root: %s, kiwi: %s, lime: %s\n", root->word,
           find(root, "kiwi") ? "found" : "missing", find(root, "lime") ? "found" : "missing");
    free_tree(root);  // children first, then the node itself
    return 0;
}
