//GlossProcessor.swift
import Foundation
internal import Speech
import NaturalLanguage

class GlossProcessor {

    // Words usually removed in ISL gloss
    let ignoredWords: Set<String> = [
        "and", "is", "am", "are","was","were",
        "the","a","an",
        "to","of","for",
        "will","shall","be","been",
        "did","do","does"
    ]

    // Time markers
    let timeWords: Set<String> = [
        "today", "tomorrow", "yesterday",
        "now", "later", "soon", "tonight",
        "morning", "afternoon", "evening", "night"
    ]

    // Question words
    let questionWords: Set<String> = [
        "what", "where", "when",
        "why", "who", "how"
    ]

    // Negation words
    let negationWords: Set<String> = [
        "not", "never", "no"
    ]


    func isVerb(_ word: String) -> Bool {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = word

        let tag = tagger.tag(
            at: word.startIndex,
            unit: .word,
            scheme: .lexicalClass
        ).0

        return tag == .verb
    }

    func lemma(for word: String) -> String {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = word

        return tagger.tag(
            at: word.startIndex,
            unit: .word,
            scheme: .lemma
        ).0?.rawValue.lowercased() ?? word.lowercased()
    }

    // MARK: - ISL Reordering

    func reorderToISL(_ words: [String]) -> [String] {

        var subjects: [String] = []
        var objects: [String] = []
        var verbs: [String] = []
        var times: [String] = []
        var negations: [String] = []
        var questions: [String] = []

        for word in words {

            let lower = word.lowercased()

            if timeWords.contains(lower) {
                times.append(lower)
            }

            else if questionWords.contains(lower) {
                questions.append(lower)
            }

            else if negationWords.contains(lower) {
                negations.append("not")
            }

            else if isVerb(lower) {

                let rootVerb = lemma(for: lower)
                verbs.append(rootVerb)
            }

            else {

                // crude subject heuristic
                if subjects.isEmpty {
                    subjects.append(lower)
                } else {
                    objects.append(lower)
                }
            }
        }

        // ISL structure:
        // TIME + SUBJECT + OBJECT + VERB + NEGATION + QUESTION

        return times
            + subjects
            + objects
            + verbs
            + negations
            + questions
    }

    //Main Pipeline

    func extractGlossTimeline(
        from segments: [SFTranscriptionSegment]
    ) -> [GlossEvent] {

        struct FlatWord {
            let word: String
            let timestamp: Double
            let duration: Double
        }

        var flatWords: [FlatWord] = []

        // Step 1: Flatten segments
        for seg in segments {

            let words = seg.substring.lowercased()
                .split(separator: " ")
                .map { String($0) }

            let timePerWord = seg.duration / Double(words.count)

            for (i, word) in words.enumerated() {

                flatWords.append(
                    FlatWord(
                        word: word,
                        timestamp: seg.timestamp + Double(i) * timePerWord,
                        duration: timePerWord
                    )
                )
            }
        }

        print("Original words:",
              flatWords.map { $0.word })

        // Step 2: Remove fillers
        let filteredWords = flatWords
            .map { $0.word }
            .filter { !ignoredWords.contains($0) }

        print("Filtered words:", filteredWords)

        // Step 3: ISL Reordering
        let reorderedWords = reorderToISL(filteredWords)

        print("ISL reordered:", reorderedWords)

        // Step 4: Generate gloss timeline

        var events: [GlossEvent] = []

        var currentTime: Double = 0

        let glossDuration: Double = 0.8

        var i = 0

        while i < reorderedWords.count {

            let word = reorderedWords[i]

            var foundPhrase = false

            let maxLookup = min(5, reorderedWords.count - i)

            // try 5-word phrase max
            for length in stride(from: maxLookup, through: 1, by: -1) {

                let phrase = reorderedWords[i..<i+length]
                    .joined(separator: " ")

                if DatabaseManager.shared.hasGloss(for: phrase) {

                    events.append(
                        GlossEvent(
                            gloss: phrase.lowercased(),
                            time: currentTime
                        )
                    )

                    currentTime += glossDuration
                    i += length
                    foundPhrase = true
                    break
                }
            }

            if foundPhrase {
                continue
            }

            // Number lookup
            if DatabaseManager.shared.hasGloss(for: word) {

                events.append(
                    GlossEvent(
                        gloss: word,
                        time: currentTime
                    )
                )

                currentTime += glossDuration
                i += 1
                continue
            }

            // Digit split
            if Int(word) != nil {

                for _ in word {

                    if DatabaseManager.shared.hasGloss(for: word) {

                        events.append(
                            GlossEvent(
                                gloss: word,
                                time: currentTime
                            )
                        )

                        currentTime += glossDuration
                        i += 1
                        continue
                    }                }

                i += 1
                continue
            }

            // Alphabet fallback
            var spelled = false

            for char in word {

                let letter = String(char).lowercased()

                if DatabaseManager.shared.hasGloss(for: letter) {

                    events.append(
                        GlossEvent(
                            gloss: letter,
                            time: currentTime
                        )
                    )

                    currentTime += 0.3
                    spelled = true
                }
            }

            if !spelled {

                // Direct gloss fallback
                events.append(
                    GlossEvent(
                        gloss: word,
                        time: currentTime
                    )
                )

                currentTime += glossDuration
            }

            i += 1
        }

        return events
    }
}
