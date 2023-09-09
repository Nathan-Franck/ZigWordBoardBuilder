const std = @import("std");

const words = @embedFile("words.txt");
const all_my_letters = "UUUUQXQXK1133774&$$$K999988551FIRSTTOOHARDELUSPRC-AIHHHIIIIIIJJLLLLOO?MONNNNNNMMMDGGGFBBBCCC!AAAAAEEEEEEEEPPPRRKRRSSTTTTWWWWKZZVYVYS&$$$K999988551";

pub fn main() !void {
    // Split words by newlines into an array of strings
    var word_iter = std.mem.split(u8, words, "\n");
    var word_list = std.ArrayList([]u8).init(std.heap.page_allocator);
    defer word_list.deinit();
    while (word_iter.next()) |word| {
        // Ignore all words that are shorter than 3 characters
        if (word.len < 3) {
            continue;
        }
        var uppercase_word = try std.ascii.allocUpperString(std.heap.page_allocator, word);
        try word_list.append(uppercase_word);
    }

    // Print first 10 words
    for (word_list.items[0..10]) |word| {
        std.debug.print("Word: {s}\n", .{word});
    }

    const FoundCombination = struct {
        word_indices: [all_my_letters.len]?usize,
        letters_used: u32,
    };

    // Found combinations is a list of FoundCombinations starting empty.
    var combinations_found = std.ArrayList(FoundCombination).init(std.heap.page_allocator);

    // Fill the pool with all the letters
    var letter_pool = [_]u8{0} ** 256;
    for (all_my_letters) |letter| {
        letter_pool[letter] += 1;
    }

    // Dump resulting array
    std.debug.print("Letter pool: {any}\n", .{letter_pool});

    // Init some crazy random number generator
    // var random = std.rand.Ascon.init(.{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 2 });
    var random = std.rand.Xoroshiro128.init(0);

    // Iterate through 1000 attempts for now...
    // Try a random combination of words that use the letters.
    for (0..100000) |_| {
        // Create a new letter pool
        var current_letter_pool = [_]u8{0} ** 256;
        std.mem.copy(u8, &current_letter_pool, &letter_pool);

        // Dump resulting array
        // std.debug.print("Current letter pool: {any}\n", .{current_letter_pool});

        var word_count: u8 = 0;
        var combination = FoundCombination{
            .word_indices = [_]?usize{null} ** all_my_letters.len,
            .letters_used = 0,
        };
        attempt: for (0..100000) |_| {
            // Pick a random word from the word list
            const word_index = random.random().int(usize) % word_list.items.len; // Constrain to size of word list
            const word = word_list.items[word_index];

            // Collect the letters from the word, check if we can use it
            var word_letter_pool = [_]u8{0} ** 256;
            for (word) |letter| {
                word_letter_pool[letter] += 1;
                if (current_letter_pool[letter] < word_letter_pool[letter]) {
                    // std.debug.print("Oh no... we can't use the word {s} because we don't have enough {c} (Requires {d}, {d} left)\n", .{ word, letter, word_letter_pool[letter], current_letter_pool[letter] });
                    continue :attempt;
                }
            }

            // If we can use the word, then use it
            for (word) |letter| {
                current_letter_pool[letter] -= 1; // panics on overflow, which is actually super nice.
                combination.letters_used += 1;
            }
            combination.word_indices[word_count] = word_index;
            word_count += 1;

            // std.debug.print("ACTUALLY USED A WORD: {s} {d}\n", .{ word, word_index });
        }
        // Whatever we got, add it to the list of combinations.
        try combinations_found.append(combination);
    }

    // Sort combinations from most letters used to least letters used
    std.sort.block(FoundCombination, combinations_found.items, {}, struct {
        fn cmpByValue(_: void, a: FoundCombination, b: FoundCombination) bool {
            return a.letters_used > b.letters_used;
        }
    }.cmpByValue);

    std.debug.print("Top 10 combinations (Best score is {d} letters out of a possible {d})\n", .{ combinations_found.items[0].letters_used, all_my_letters.len });

    // Print the top 10 combinations
    for (combinations_found.items[0..10], 1..) |combination, index| {
        std.debug.print("Combination: {d} ({d} letters)\n", .{ index, combination.letters_used });
        for (combination.word_indices) |word_index_or_null| {
            if (word_index_or_null) |word_index| {
                const word = word_list.items[word_index];
                std.debug.print("  {s}\n", .{word});
            }
        }
    }
}
