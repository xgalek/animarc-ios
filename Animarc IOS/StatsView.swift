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
    @State private var selectedPeriod: TimePeriod = .week
    
    // Hardcoded chart data for last 7 days
    private let chartData: [ChartDataPoint] = [
        ChartDataPoint(day: "Mon", hours: 2.0),
        ChartDataPoint(day: "Tue", hours: 1.5),
        ChartDataPoint(day: "Wed", hours: 3.0),
        ChartDataPoint(day: "Thu", hours: 2.0),
        ChartDataPoint(day: "Fri", hours: 1.0),
        ChartDataPoint(day: "Sat", hours: 2.5),
        ChartDataPoint(day: "Sun", hours: 1.5)
    ]
    
    // Hardcoded recent sessions data
    private let recentSessions: [(date: String, duration: String, xp: Int)] = [
        ("Today, 2:30 PM", "25:43", 50),
        ("Today, 10:15 AM", "30:12", 60),
        ("Yesterday, 4:45 PM", "45:30", 90),
        ("Yesterday, 1:20 PM", "20:15", 40),
        ("Dec 1, 9:00 AM", "35:22", 70),
        ("Dec 1, 3:15 PM", "28:45", 55),
        ("Nov 30, 11:30 AM", "40:10", 80),
        ("Nov 30, 2:00 PM", "22:33", 45),
        ("Nov 29, 10:45 AM", "50:20", 100),
        ("Nov 29, 4:20 PM", "18:55", 35)
    ]
    
    var body: some View {
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
                            }) {
                                Text(period.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(selectedPeriod == period ? .white : Color(hex: "#9CA3AF"))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedPeriod == period
                                            ? Color(hex: "#8B5CF6")
                                            : Color.clear
                                    )
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Key Metrics Section
                    VStack(alignment: .leading, spacing: 16) {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            MetricCard(title: "Total Focus Time", value: "12h 45m")
                            MetricCard(title: "Total Sessions", value: "23")
                            MetricCard(title: "Average Session", value: "33 min")
                            MetricCard(title: "Longest Session", value: "1h 45m")
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Chart Section
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
                    
                    // Recent Sessions Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Sessions")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            ForEach(Array(recentSessions.enumerated()), id: \.offset) { index, session in
                                SessionRow(
                                    date: session.date,
                                    duration: session.duration,
                                    xp: session.xp
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
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
}
