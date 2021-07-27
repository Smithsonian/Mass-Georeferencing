#!/usr/bin/env python3

import difflib
from SPARQLWrapper import SPARQLWrapper, JSON

BASE_URI = "http://vocabsservices.getty.edu/AATService.asmx/AATGetTermMatch?term="
END_URI = "&logop=and&notes="


class Recon:

    def __init__(self, score):
        """Turns the lists of scores and term-id pairs into objects"""
        self.score = score[0]
        self.term = score[1][0]
        self.id = score[1][1]
        self.uri = get_term_uri(self.id).replace('http://vocab.getty.edu/aat/', '')

    def __str__(self):
        return str(self.term) + " (" + str(self.score) + ")"


class SPARQLQuery:

    def __init__(self, search_term):
        """Perform AAT genre searches by querying the controlled vocabulary's SPARQL endpoint"""
        self.term = search_term
        self.results = self.query_sparql_endpoint()

    def __repr__(self):
        return self.results

    def query_sparql_endpoint(self):
        sparql = SPARQLWrapper("http://vocab.getty.edu/sparql")
        # sparql.setQuery("""
        #     SELECT ?Subject ?Term  WHERE {
        #     ?Subject a skos:Concept; luc:term \"""" + self.term + """\"; skos:inScheme aat: ;
        #     gvp:prefLabelGVP [xl:literalForm ?Term].
        #     } ORDER BY asc(lcase(str(?Term)))
        #     """)
        # Getting more fields
        sparql.setQuery("""
                select ?Subject ?Term ?Parents ?Descr ?ScopeNote ?Type (coalesce(?Type1,?Type2) as ?ExtraType) {
                  ?Subject luc:term \"""" + self.term + """\"; skos:inScheme aat: ; a ?typ.
                  ?typ rdfs:subClassOf gvp:Subject; rdfs:label ?Type.
                  filter (?typ != gvp:Subject)
                  optional {?Subject gvp:placeTypePreferred [gvp:prefLabelGVP [xl:literalForm ?Type1]]}
                  optional {?Subject gvp:agentTypePreferred [gvp:prefLabelGVP [xl:literalForm ?Type2]]}
                  optional {?Subject gvp:prefLabelGVP [xl:literalForm ?Term]}
                  optional {?Subject gvp:parentStringAbbrev ?Parents}
                  optional {?Subject foaf:focus/gvp:biographyPreferred/schema:description ?Descr}
                  optional {?Subject skos:scopeNote [dct:language gvp_lang:en; rdf:value ?ScopeNote]}}
            """)
        sparql.setReturnFormat(JSON)
        results = sparql.query().convert()
        if results:
            term_id_pairs = [(r["Term"]["value"], r["Subject"]["value"])
                             for r in results["results"]["bindings"]]
            return term_id_pairs
        return None


def get_term_uri(term_id, extension="html", include_ext=False):
    """:return: the URI of a term, given the retrieved ID"""
    if "http://" in term_id:
        return term_id
    term_uri = "http://vocab.getty.edu/page/aat/" + term_id
    if include_ext:
        return term_uri + "." + extension
    return term_uri


def reconcile(search_term, term_id_pairs, sort=False, limit=5):
    """appends a reconciliation score to each aat_term-identifier pair"""
    recon_scores = []
    for t in term_id_pairs:
        # NOTE: assumes 0th element of tuple == aat_term
        aat_term = t[0].lower()
        if aat_term.endswith("."):
            aat_term = aat_term[-1]
        sim_ratio = str(round(float(difflib.SequenceMatcher(
            None,
            search_term.lower(),
            aat_term).ratio()), 3))
        recon_scores.append([sim_ratio, t])
    if sort:
        return sorted(recon_scores,
                      key=lambda x: x[0],
                      reverse=True)[:limit]
    return recon_scores[:limit]
