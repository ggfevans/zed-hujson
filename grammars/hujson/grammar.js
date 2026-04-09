/**
 * @file HuJSON (JWCC) grammar for tree-sitter
 * @author Max Brunsfeld <maxbrunsfeld@gmail.com> (original tree-sitter-json)
 * @author Amaan Qureshi <amaanq12@gmail.com> (original tree-sitter-json)
 * @author Gareth Evans <gareth.gwilym.frederick.evans@gmail.com> (HuJSON fork)
 * @license MIT
 *
 * Forked from tree-sitter-json at commit 001c28d7a29832b06b0e831ec77845553c89b56d.
 * Modification: commaSep/commaSep1 helpers tolerate an optional trailing comma
 * per the JWCC (JSON With Commas and Comments) specification.
 *
 * @see {@link https://github.com/tailscale/hujson|HuJSON}
 * @see {@link https://nigeltao.github.io/blog/2021/json-with-commas-comments.html|JWCC spec}
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: 'hujson',

  extras: $ => [
    /\s/,
    $.comment,
  ],

  supertypes: $ => [
    $._value,
  ],

  rules: {
    document: $ => repeat($._value),

    _value: $ => choice(
      $.object,
      $.array,
      $.number,
      $.string,
      $.true,
      $.false,
      $.null,
    ),

    object: $ => seq(
      '{', commaSep($.pair), '}',
    ),

    pair: $ => seq(
      field('key', choice($.string, $.number)),
      ':',
      field('value', $._value),
    ),

    array: $ => seq(
      '[', commaSep($._value), ']',
    ),

    string: $ => choice(
      seq('"', '"'),
      seq('"', $.string_content, '"'),
    ),

    string_content: $ => repeat1(choice(
      token.immediate(prec(1, /[^\\"\n]+/)),
      $.escape_sequence,
    )),

    escape_sequence: _ => token.immediate(seq(
      '\\',
      /(\"|\\|\/|b|f|n|r|t|u[0-9a-fA-F]{4})/,
    )),

    number: _ => {
      const decimalDigits = /\d+/;
      const exponentPart = seq(choice('e', 'E'), optional(choice('+', '-')), decimalDigits);

      const decimalIntegerLiteral = choice(
        '0',
        seq(optional('-'), /[1-9]/, optional(decimalDigits)),
      );

      const decimalLiteral = choice(
        seq(decimalIntegerLiteral, '.', optional(decimalDigits), optional(exponentPart)),
        seq(decimalIntegerLiteral, optional(exponentPart)),
        seq(optional('-'), '.', decimalDigits, optional(exponentPart)),
      );

      return token(decimalLiteral);
    },

    true: _ => 'true',

    false: _ => 'false',

    null: _ => 'null',

    comment: _ => token(choice(
      seq('//', /[^\r\n]*/),
      seq('/*', /[^*]*\*+([^/*][^*]*\*+)*/, '/'),
    )),
  },
});

/**
 * Creates a rule to match one or more occurrences of `rule` separated by
 * commas, with an optional trailing comma (JWCC extension).
 *
 * @param {Rule} rule
 * @returns {SeqRule}
 */
function commaSep1(rule) {
  return seq(rule, repeat(seq(',', rule)), optional(','));
}

/**
 * Creates a rule to optionally match one or more occurrences of `rule`
 * separated by commas, with an optional trailing comma (JWCC extension).
 *
 * @param {Rule} rule
 * @returns {ChoiceRule}
 */
function commaSep(rule) {
  return optional(commaSep1(rule));
}
