package tree_sitter_hujson_test

import (
	"testing"

	tree_sitter "github.com/smacker/go-tree-sitter"
	"github.com/tree-sitter/tree-sitter-hujson"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_hujson.Language())
	if language == nil {
		t.Errorf("Error loading Hujson grammar")
	}
}
