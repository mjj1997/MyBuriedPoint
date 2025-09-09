#pragma once

#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include <cstdint>

namespace buried_point {

class Database
{
public:
    struct Data
    {
        int32_t id;
        int32_t priority;
        uint64_t timestamp;
        std::string content;
    };

public:
    explicit Database(std::string_view path);
    ~Database();

    void insert(const Data& data);
    void remove(const Data& data);
    void remove(const std::vector<Data>& dataset);
    std::vector<Data> query(int32_t limit) const;

private:
    class Impl;
    std::unique_ptr<Impl> d_ptr;
};

} // namespace buried_point
