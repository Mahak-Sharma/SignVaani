import Foundation
import Speech
//GlossProcessor takes speech segments → converts into gloss timeline
class GlossProcessor {
    let phraseDictionary = PhraseDictionary.shared.phrases
    //Maps phrases with gloss
    let alphabetDictionary = AlphabetDictionary.shared.alphabet
    // Maps Alphabets with spelling gloss
    // these are gramatically useless in sign language
    let numbersDictionary = NumbersDictionary.shared.numbers//to detect numbers
    let ignoredWords: Set<String> = [
        "is","am","are","was","were",
        "the","a","an",
        "to","of","for",
        "will","shall","be","been"
    ]
    private let timeWords: Set<String> = [
        "today", "tomorrow", "yesterday",
        "now", "later", "soon", "tonight",
        "morning", "afternoon", "evening", "night"
    ]
    private let verbWords: Set<String> = [
        "go", "goes", "going", "went",
        "come", "comes", "coming", "came",
        "eat", "eats", "eating", "ate",
        "meet", "meets", "meeting", "met",
        "play", "plays", "playing", "played",
        "study", "studies", "studying", "studied",
        "learn", "learns", "learning", "learned",
        "read", "reads", "reading",
        "write", "writes", "writing", "wrote",
        "watch", "watches", "watching", "watched",
        "speak", "speaks", "speaking", "spoke",
        "visit", "visits", "visiting", "visited",
        "buy", "buys", "buying", "bought"
    ]
    // dictionary se longest phrase length auto detect phrases ko spilt karta hai count number of words then maximum find karta hai
    lazy var maxPhraseLength: Int = {
        phraseDictionary.keys
            .map { $0.split(separator: " ").count }
            .max() ?? 1
    }()

    func reorderToISL(_ words: [String]) -> [String] {
        guard words.count > 2 else { return words }

        let subject = words[0]
        let remainingWords = Array(words.dropFirst())

        var objects: [String] = []
        var times: [String] = []
        var verbs: [String] = []

        for word in remainingWords {
            if timeWords.contains(word) {
                times.append(word)
            } else if isLikelyVerb(word) {
                verbs.append(word)
            } else {
                objects.append(word)
            }
        }

        return [subject] + objects + times + verbs
    }

    private func isLikelyVerb(_ word: String) -> Bool {
        verbWords.contains(word)
    }
    
    func extractGlossTimeline(from segments: [SFTranscriptionSegment]) -> [GlossEvent] {
        // Step 1: Flatten multi-word segments into individual words
        struct FlatWord {
            let word: String
            let timestamp: Double
            let duration: Double
        }
        var flatWords: [FlatWord] = []
        for seg in segments {
            let words = seg.substring.lowercased()
                .split(separator: " ")
                .map { String($0) }
            
            if words.count == 1 {
                flatWords.append(FlatWord(word: words[0], timestamp: seg.timestamp, duration: seg.duration))
            } else {
                // Distribute time evenly across words in segment
                let timePerWord = seg.duration / Double(words.count)
                for (i, word) in words.enumerated() {
                    flatWords.append(FlatWord(
                        word: word,
                        timestamp: seg.timestamp + Double(i) * timePerWord,
                        duration: timePerWord
                    ))
                }
            }
        }
        
        print("Flat words:", flatWords.map { $0.word })
        
        // Step 2: Remove ignored words before reordering.
        let words = flatWords.map { $0.word }
        let filteredWords = words.filter { !ignoredWords.contains($0) }

        // Step 3: Reorder into a simple ISL-friendly SOV shape.
        let reorderedWords = reorderToISL(filteredWords)
        let reorderedTimestamp = flatWords.last.map { $0.timestamp + $0.duration } ?? 0
        let reorderedFlatWords = reorderedWords.map {
            FlatWord(word: $0, timestamp: reorderedTimestamp, duration: 0)
        } 

        print("Filtered words:", filteredWords)
        print("Reordered words:", reorderedWords)

        // Step 4: Run existing gloss mapping on the reordered words.
        var events: [GlossEvent] = []
        var i = 0
        
        while i < reorderedFlatWords.count {
            let word = reorderedFlatWords[i].word
            
            var foundPhrase = false
            
            // Phrase lookup (multi-word)
            for length in stride(from: min(maxPhraseLength, reorderedFlatWords.count - i), through: 1, by: -1) {
                let phrase = reorderedFlatWords[i..<i+length]
                    .map { $0.word }
                    .joined(separator: " ")
                
                if let gloss = phraseDictionary[phrase] {
                    print("Phrase detected:", phrase, "->", gloss)
                    let last = reorderedFlatWords[i + length - 1]
                    let endTime = last.timestamp + last.duration
                    events.append(GlossEvent(gloss: gloss.lowercased(), time: endTime))
                    i += length
                    foundPhrase = true
                    break
                }
            }
            if foundPhrase { continue }
            
            // Number detection
            if let numberGloss = numbersDictionary[word] {
                let endTime = reorderedFlatWords[i].timestamp + reorderedFlatWords[i].duration
                events.append(GlossEvent(gloss: numberGloss, time: endTime))
                i += 1
                continue
            }
            
            // Number split digit-wise
            if Int(word) != nil {
                let endTime = reorderedFlatWords[i].timestamp + reorderedFlatWords[i].duration
                for digit in word {
                    if let gloss = numbersDictionary[String(digit)] {
                        events.append(GlossEvent(gloss: gloss, time: endTime))
                    }
                }
                i += 1
                continue
            }
            
            // Alphabet fallback
            let endTime = reorderedFlatWords[i].timestamp + reorderedFlatWords[i].duration
            for char in word {
                if let letter = alphabetDictionary[char] {
                    events.append(GlossEvent(gloss: letter, time: endTime))
                }
            }
            i += 1
        }
        
        return events
    }
}
