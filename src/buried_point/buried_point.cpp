#include <MyBuriedPoint/buried_point.h>

#include <spdlog/common.h>
#include <spdlog/logger.h>
#include <spdlog/sinks/basic_file_sink.h>
#include <spdlog/sinks/stdout_color_sinks.h>
#include <spdlog/spdlog.h>

#include <filesystem>
#include <memory>
#include <string_view>
#include <vector>

BuriedPoint::BuriedPoint(std::string_view logPath)
{
    // init log path
    std::filesystem::path path{ logPath };
    if (!std::filesystem::exists(path)) {
        std::filesystem::create_directories(path);
    }

    m_logPath = path / "buried_point";
    if (!std::filesystem::exists(m_logPath)) {
        std::filesystem::create_directories(m_logPath);
    }

    // init logger
    auto consoleSink{ std::make_shared<spdlog::sinks::stdout_color_sink_mt>() };

    path = m_logPath / "buried_point.log";
    auto fileSink{ std::make_shared<spdlog::sinks::basic_file_sink_mt>(path.string(), true) };

    std::vector<spdlog::sink_ptr> sinks;
    sinks.push_back(consoleSink);
    sinks.push_back(fileSink);

    m_logger = std::make_shared<spdlog::logger>("BuriedPoint", sinks.begin(), sinks.end());
    m_logger->set_level(spdlog::level::trace);
    m_logger->set_pattern("[%c] [%s:%#] [%l] %v");

    SPDLOG_LOGGER_INFO(logger(), "BuriedPoint initialized, working path: {}", m_logPath.string());
}

std::shared_ptr<spdlog::logger> BuriedPoint::logger()
{
    return m_logger;
}
