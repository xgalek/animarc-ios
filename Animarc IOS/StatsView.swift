//
//  StatsView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI
import Charts

enum TimePeriod: String, CaseIterable {
    case today = "Today"
    case week = "Week"
    case month = "Month"
    case allTime = "All Time"
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let day: String
    let hours: Double
}

struct StatsView: View {
    @EnvironmentObject var progressManager: UserProgressManager
    @State private var selectedPeriod: TimePeriod = .week
    @State private var chartData: [ChartDataPoint] = []
    @State private var displayedSessions: [FocusSession] = []
    @State private var stats: (totalMinutes: Int, totalXP: Int, avgMinutes: Int, longestMinutes: Int) = (0, 0, 0, 0)
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "#1A2332")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Top Section - Title
                        HStack {
                            Text("Statistics")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Time Period Selector
                        HStack(spacing: 12) {
                            ForEach(TimePeriod.allCases, id: \.self) { period in
                                Button(action: {
                                    selectedPeriod = period
                                    Task {
                                        await loadDataForPeriod()
                                    }
                                }) {
                                    Text(period.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedPeriod == period ? .white : Color(hex: "#9CA3AF"))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedPeriod == period
                                                ? Color(hex: "#FF9500")
                                                : Color.clear
                                        )
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Key Metrics Section
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.vertical, 40)
                        } else {
                            VStack(alignment: .leading, spacing: 16) {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ], spacing: 12) {
                                    MetricCard(title: "Total Focus Time", value: formatMinutes(stats.totalMinutes))
                                    MetricCard(title: "Total Sessions", value: "\(displayedSessions.count)")
                                    MetricCard(title: "Average Session", value: "\(stats.avgMinutes) min")
                                    MetricCard(title: "Longest Session", value: formatMinutes(stats.longestMinutes))
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Chart Section (only for Week view)
                            if selectedPeriod == .week && !chartData.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("This Week")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                    
                                    Chart(chartData) { data in
                                        BarMark(
                                            x: .value("Day", data.day),
                                            y: .value("Hours", data.hours)
                                        )
                                        .foregroundStyle(Color(hex: "#22C55E"))
                                        .cornerRadius(4)
                                    }
                                    .frame(height: 200)
                                    .chartXAxis {
                                        AxisMarks(values: .automatic) { _ in
                                            AxisValueLabel()
                                                .foregroundStyle(.white.opacity(0.7))
                                                .font(.system(size: 12))
                                        }
                                    }
                                    .chartYAxis {
                                        AxisMarks(position: .leading, values: .automatic) { _ in
                                            AxisValueLabel()
                                                .foregroundStyle(.white.opacity(0.7))
                                                .font(.system(size: 12))
                                            AxisGridLine()
                                                .foregroundStyle(.white.opacity(0.1))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            // Recent Sessions Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Recent Sessions")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                
                                if displayedSessions.isEmpty {
                                    Text("No sessions yet")
                                        .font(.subheadline)
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 40)
                                } else {
                                    VStack(spacing: 12) {
                                        ForEach(displayedSessions.prefix(10)) { session in
                                            SessionRow(
                                                date: formatSessionDate(session.completedAt),
                                                duration: formatSessionDuration(session.durationMinutes),
                                                xp: session.xpEarned
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
        }
        .task {
            await loadDataForPeriod()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadDataForPeriod() async {
        isLoading = true
        
        let calendar = Calendar.current
        let now = Date()
        var sessions: [FocusSession] = []
        
        switch selectedPeriod {
        case .today:
            sessions = await progressManager.getSessionsToday()
            
        case .week:
            sessions = await progressManager.getSessionsThisWeek()
            chartData = buildWeekChartData(from: sessions)
            
        case .month:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            sessions = await fetchSessions(from: startOfMonth, to: endOfMonth)
            
        case .allTime:
            sessions = progressManager.recentSessions
        }
        
        displayedSessions = sessions
        stats = progressManager.calculateStats(sessions: sessions)
        isLoading = false
    }
    
    private func fetchSessions(from startDate: Date, to endDate: Date) async -> [FocusSession] {
        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
            return []
        }
        
        do {
            return try await SupabaseManager.shared.fetchSessionsInRange(
                userId: userId,
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            print("Failed to fetch sessions: \(error)")
            return []
        }
    }
    
    private func buildWeekChartData(from sessions: [FocusSession]) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Create data for last 7 days
        var dayData: [String: Double] = [:]
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        // Initialize all days to 0
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -6 + i, to: today) {
                let weekday = calendar.component(.weekday, from: date) - 1
                dayData[dayNames[weekday]] = 0
            }
        }
        
        // Sum up session minutes per day
        for session in sessions {
            let sessionDay = calendar.startOfDay(for: session.completedAt)
            let weekday = calendar.component(.weekday, from: sessionDay) - 1
            let dayName = dayNames[weekday]
            dayData[dayName, default: 0] += Double(session.durationMinutes) / 60.0
        }
        
        // Build chart data in order (starting from 7 days ago)
        var chartPoints: [ChartDataPoint] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -6 + i, to: today) {
                let weekday = calendar.component(.weekday, from: date) - 1
                let dayName = dayNames[weekday]
                chartPoints.append(ChartDataPoint(day: dayName, hours: dayData[dayName] ?? 0))
            }
        }
        
        return chartPoints
    }
    
    // MARK: - Formatting Helpers
    
    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
        return "\(minutes) min"
    }
    
    private func formatSessionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'Today,' h:mm a"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "'Yesterday,' h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        
        return formatter.string(from: date)
    }
    
    private func formatSessionDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return String(format: "%d:%02d:00", hours, mins)
        }
        return String(format: "%02d:00", mins)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#9CA3AF"))
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: "#243447"))
        .cornerRadius(12)
    }
}

struct SessionRow: View {
    let date: String
    let duration: String
    let xp: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(date)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Text(duration)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#9CA3AF"))
            }
            
            Spacer()
            
            Text("+\(xp) XP")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "#22C55E"))
        }
        .padding(16)
        .background(Color(hex: "#243447"))
        .cornerRadius(12)
    }
}

#Preview {
    StatsView()
        .environmentObject(UserProgressManager.shared)
}
