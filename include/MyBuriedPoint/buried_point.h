#pragma once

#include <filesystem>
#include <memory>
#include <string_view>

class BuriedPoint
{
public:
    explicit BuriedPoint(std::string_view logPath);
    ~BuriedPoint() = default;

    std::shared_ptr<spdlog::logger> logger();

private:
    std::filesystem::path m_logPath;
    std::shared_ptr<spdlog::logger> m_logger;
};
