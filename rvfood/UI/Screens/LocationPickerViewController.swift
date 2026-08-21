import CoreLocation
import UIKit

final class LocationPickerViewController: UIViewController {

    private struct PresetLocation {
        let title: String
        let point: GeoPoint
    }

    private let presets: [PresetLocation] = [
        PresetLocation(title: "RS Puram, Coimbatore", point: GeoPoint(latitude: 11.0168, longitude: 76.9558)),
        PresetLocation(title: "Gandhipuram, Coimbatore", point: GeoPoint(latitude: 11.0185, longitude: 76.9674)),
        PresetLocation(title: "Peelamedu, Coimbatore", point: GeoPoint(latitude: 11.0297, longitude: 77.0276)),
        PresetLocation(title: "Ukkadam, Coimbatore", point: GeoPoint(latitude: 10.9975, longitude: 76.9495)),
        PresetLocation(title: "Saibaba Colony, Coimbatore", point: GeoPoint(latitude: 11.0268, longitude: 76.9443))
    ]

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select Location"
        view.backgroundColor = .systemGroupedBackground

        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        statusLabel.frame = CGRect(x: 16, y: 0, width: view.bounds.width - 32, height: 40)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SubtitleCell.self, forCellReuseIdentifier: SubtitleCell.reuseID)
        tableView.tableHeaderView = statusLabel
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func useCurrentLocation() {
        statusLabel.text = "Finding your location…"
        Task {
            let service = LocationService.shared
            let granted = await service.requestPermission()
            guard granted else {
                statusLabel.text = "Location permission denied. Choose a location below instead."
                return
            }
            do {
                let location = try await service.currentLocation()
                let coordinate = location.coordinate
                let title = await service.reverseGeocode(coordinate: coordinate) ?? "Current location"
                SelectedLocationStore.shared.update(
                    point: GeoPoint(coordinate: coordinate),
                    title: title
                )
                navigationController?.popViewController(animated: true)
            } catch {
                statusLabel.text = "Could not get your location. Choose a location below."
            }
        }
    }

    private func select(preset: PresetLocation) {
        SelectedLocationStore.shared.update(point: preset.point, title: preset.title)
        navigationController?.popViewController(animated: true)
    }
}

extension LocationPickerViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : presets.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? nil : "Popular Areas"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SubtitleCell.reuseID, for: indexPath)
        if indexPath.section == 0 {
            cell.textLabel?.text = "📍 Use my current location"
            cell.detailTextLabel?.text = "Get shops near you right now"
            cell.textLabel?.textColor = .systemOrange
        } else {
            let preset = presets[indexPath.row]
            cell.textLabel?.text = preset.title
            cell.detailTextLabel?.text = nil
            cell.textLabel?.textColor = .label
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            useCurrentLocation()
        } else {
            select(preset: presets[indexPath.row])
        }
    }
}
