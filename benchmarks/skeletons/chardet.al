flow chardet_lib:
  steps:
    - chardistribution_group
    - charsetprober_group
    - cli_chardetect_group
    - enums_group
    - universaldetector_group
    - utf1632prober_group


flow chardistribution_group:
  steps:
    - CharDistributionAnalysis__reset
    - CharDistributionAnalysis__feed
    - CharDistributionAnalysis__get_confidence


flow charsetprober_group:
  steps:
    - CharSetProber__filter_international_words
    - CharSetProber__remove_xml_tags


flow cli_chardetect_group:
  steps:
    - description_of
    - main


flow enums_group:
  steps:
    - SequenceLikelihood__get_num_categories


flow universaldetector_group:
  steps:
    - UniversalDetector__reset
    - UniversalDetector__feed
    - UniversalDetector__close


flow utf1632prober_group:
  steps:
    - UTF1632Prober__validate_utf32_characters
    - UTF1632Prober__validate_utf16_characters


code CharDistributionAnalysis__reset:
  body: |
    def reset(self):
        """reset analyser, clear any state"""
        pass


code CharDistributionAnalysis__feed:
  body: |
    def feed(self, char, char_len):
        """feed a character with known length"""
        pass


code CharDistributionAnalysis__get_confidence:
  body: |
    def get_confidence(self):
        """return confidence based on existing data"""
        pass


code CharSetProber__filter_international_words:
  body: |
    def filter_international_words(buf):
        """
            We define three types of bytes:
            alphabet: english alphabets [a-zA-Z]
            international: international characters [-ÿ]
            marker: everything else [^a-zA-Z-ÿ]
            The input buffer can be thought to contain a series of words delimited
            by markers. This function works to filter all words that contain at
            least one international character. All contiguous sequences of markers
            are replaced by a single space ascii character.
            This filter applies to all scripts which do not use English characters.
            
        """
        pass


code CharSetProber__remove_xml_tags:
  body: |
    def remove_xml_tags(buf):
        """
            Returns a copy of ``buf`` that retains only the sequences of English
            alphabet and high byte characters that are not between <> characters.
            This filter can be applied to all scripts which contain both English
            characters and extended ASCII characters, but is currently only used by
            ``Latin1Prober``.
            
        """
        pass


code description_of:
  body: |
    def description_of(lines, name='stdin'):
        """
        Return a string describing the probable encoding of a file or
        list of strings.
    
        :param lines: The lines to get the encoding of.
        :type lines: Iterable of bytes
        :param name: Name of file or collection of lines
        :type name: str
        
        """
        pass


code main:
  body: |
    def main(argv=None):
        """
        Handles command line arguments and gets things started.
    
        :param argv: List of arguments, as if specified on the command-line.
                     If None, ``sys.argv[1:]`` is used instead.
        :type argv: list of str
        
        """
        pass


code SequenceLikelihood__get_num_categories:
  body: |
    def get_num_categories(cls):
        """:returns: The number of likelihood categories in the enum."""
        pass


code UniversalDetector__reset:
  body: |
    def reset(self):
        """
            Reset the UniversalDetector and all of its probers back to their
            initial states.  This is called by ``__init__``, so you only need to
            call this directly in between analyses of different documents.
            
        """
        pass


code UniversalDetector__feed:
  body: |
    def feed(self, byte_str):
        """
            Takes a chunk of a document and feeds it through all of the relevant
            charset probers.
    
            After calling ``feed``, you can check the value of the ``done``
            attribute to see if you need to continue feeding the
            ``UniversalDetector`` more data, or if it has made a prediction
            (in the ``result`` attribute).
    
            .. note::
               You should always call ``close`` when you're done feeding in your
               document if ``done`` is not already ``True``.
            
        """
        pass


code UniversalDetector__close:
  body: |
    def close(self):
        """
            Stop analyzing the current document and come up with a final
            prediction.
    
            :returns:  The ``result`` attribute, a ``dict`` with the keys
                       `encoding`, `confidence`, and `language`.
            
        """
        pass


code UTF1632Prober__validate_utf32_characters:
  body: |
    def validate_utf32_characters(self, quad):
        """
            Validate if the quad of bytes is valid UTF-32.
    
            UTF-32 is valid in the range 0x00000000 - 0x0010FFFF
            excluding 0x0000D800 - 0x0000DFFF
    
            https://en.wikipedia.org/wiki/UTF-32
            
        """
        pass


code UTF1632Prober__validate_utf16_characters:
  body: |
    def validate_utf16_characters(self, pair):
        """
            Validate if the pair of bytes is  valid UTF-16.
    
            UTF-16 is valid in the range 0x0000 - 0xFFFF excluding 0xD800 - 0xFFFF
            with an exception for surrogate pairs, which must be in the range
            0xD800-0xDBFF followed by 0xDC00-0xDFFF
    
            https://en.wikipedia.org/wiki/UTF-16
            
        """
        pass
