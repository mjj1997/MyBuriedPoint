#include <catch2/catch_test_macros.hpp>

#include "../src/buried_point/database/database.h"

#include <cstdint>
#include <filesystem>
#include <vector>

TEST_CASE("DatabaseTest", "[database]")
{
    const std::filesystem::path dbPath{ "hello_world.db" };
    if (std::filesystem::exists(dbPath)) {
        std::filesystem::remove(dbPath);
    }

    buried_point::Database database{ dbPath.string() };
    const auto limit{ 10 };
    auto dataset = database.query(limit);
    REQUIRE(dataset.empty());

    // test insert(const Data&)
    for (int i{ 1 }; i <= limit; ++i) {
        const buried_point::Database::Data data{ .id = -1,
                                                 .priority = i,
                                                 .timestamp = static_cast<uint64_t>(i),
                                                 .content = std::string{ "hello" } };
        database.insert(data);
        dataset = database.query(limit);
        REQUIRE(dataset.size() == i);
    }

    // test remove(const Data&)
    database.remove(dataset.at(0));
    dataset = database.query(limit);
    REQUIRE(dataset.size() == 9);

    // test remove(const vector<Data>&)
    database.remove(dataset);
    dataset = database.query(limit);
    REQUIRE(dataset.empty());

    std::filesystem::remove(dbPath);
}
