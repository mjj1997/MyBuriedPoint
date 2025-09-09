#include "database.h"

#include <sqlite_orm/sqlite_orm.h>

#include <cstdint>
#include <memory>
#include <string_view>
#include <vector>

namespace buried_point {

inline auto createStorage(std::string_view path)
{
    return sqlite_orm::make_storage(
        std::string{ path },
        sqlite_orm::make_table("buried_data",
                               sqlite_orm::make_column("id",
                                                       &Database::Data::id,
                                                       sqlite_orm::primary_key().autoincrement()),
                               sqlite_orm::make_column("priority", &Database::Data::priority),
                               sqlite_orm::make_column("timestamp", &Database::Data::timestamp),
                               sqlite_orm::make_column("content", &Database::Data::content)));
}

class Database::Impl
{
    using DBStorage = decltype(createStorage(""));

public:
    explicit Impl(std::string_view path);
    ~Impl() = default;

    Impl(const Impl&) = delete;
    Impl& operator=(const Impl&) = delete;
    Impl(Impl&&) = delete;
    Impl& operator=(Impl&&) = delete;

    void insert(const Database::Data& data);
    void remove(const Database::Data& data);
    void remove(const std::vector<Database::Data>& dataset);
    std::vector<Database::Data> query(int32_t limit);

private:
    std::string m_path;
    std::unique_ptr<DBStorage> m_storage;
};

Database::Impl::Impl(std::string_view path)
    : m_path{ path }
    , m_storage{ std::make_unique<DBStorage>(createStorage(m_path)) }
{
    m_storage->sync_schema();
}

void Database::Impl::insert(const Database::Data& data)
{
    auto guard{ m_storage->transaction_guard() };

    m_storage->insert(data);

    guard.commit();
}

void Database::Impl::remove(const Database::Data& data)
{
    auto guard{ m_storage->transaction_guard() };

    m_storage->remove_all<Database::Data>(
        sqlite_orm::where(sqlite_orm::c(&Database::Data::id) == data.id));

    guard.commit();
}

void Database::Impl::remove(const std::vector<Database::Data>& dataset)
{
    auto guard{ m_storage->transaction_guard() };

    for (const auto& data : dataset) {
        m_storage->remove_all<Database::Data>(
            sqlite_orm::where(sqlite_orm::c(&Database::Data::id) == data.id));
    }

    guard.commit();
}

std::vector<Database::Data> Database::Impl::query(int32_t limit)
{
    return m_storage->get_all<Database::Data>(sqlite_orm::order_by(&Database::Data::priority).desc(),
                                              sqlite_orm::limit(limit));
}

Database::Database(std::string_view path)
    : d_ptr{ std::make_unique<Impl>(path) }
{}

Database::~Database() = default;

void Database::insert(const Data& data)
{
    d_ptr->insert(data);
}

void Database::remove(const Data& data)
{
    d_ptr->remove(data);
}

void Database::remove(const std::vector<Data>& dataset)
{
    d_ptr->remove(dataset);
}

std::vector<Database::Data> Database::query(int32_t limit) const
{
    return d_ptr->query(limit);
}

} // namespace buried_point
