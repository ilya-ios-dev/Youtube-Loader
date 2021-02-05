//
//  PlayerSongsListViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 02.02.2021.
//

import UIKit
import CoreData

/// A view controller that specializes in displaying the song list of the current player.
final class PlayerSongsListViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var backingImageView: UIImageView!
    @IBOutlet private weak var dimmerView: UIView!
    @IBOutlet private weak var cardView: UIView!
    @IBOutlet private weak var cardViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var handleView: UIView!
    
    //MARK: - Properties
    public var backingImage: UIImage?
    public var sourceProtocol: PlayerSourceProtocol!
    public var songs: [Song] {
        return audioPlayer.getOrderingSongs()
    }
    
    private var filteredSongs = [Song]()
    private var cardViewState : CardViewState = .normal
    private var cardPanStartingTopConstraint : CGFloat = 30.0
    private var fetchedResultsController: NSFetchedResultsController<Song>!
    private var dataSource: UITableViewDiffableDataSource<Int, Song>!
    private var snapshot: NSDiffableDataSourceSnapshot<Int, Song>!
    private var searchText = ""
    private var audioPlayer: AudioPlayer {
        return sourceProtocol.audioPlayer
    }
    private var window: UIWindow? {
        return UIApplication.shared.windows.filter({$0.isKeyWindow}).first
    }
    private var context: NSManagedObjectContext = {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }()
    
    //MARK: - View Life Cycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showCard()
        tableView.contentInset = .init(top: searchBar.frame.height, left: 0, bottom: view.safeAreaInsets.bottom, right: 0)
        if let selectedSong = audioPlayer.currentSong {
            let songIndex = dataSource.indexPath(for: selectedSong)
            tableView.selectRow(at: songIndex, animated: true, scrollPosition: .top)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //UI
        configureViews()
        configureTapGesture()
        configurePanGesture()
        configureSearchBar()
        configureTableView()
        
        //Data
        setupDiffableDataSource()
    }
}

//MARK: - Supporting Methods
extension PlayerSongsListViewController {
    private func configureSearchBar() {
        searchBar.delegate = self
        
        searchBar.backgroundImage = UIImage()
        guard let searchTextField: UITextField = searchBar.value(forKey: "searchField") as? UITextField else { return }
        guard let imageView = searchTextField.leftView as? UIImageView else { return }
        searchTextField.textColor = .black
        
        let attributeDict = [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        searchTextField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: attributeDict)
        
        imageView.tintColor = UIColor.lightGray
        imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
        
        searchBar.searchTextField.backgroundColor = .clear
        let view = UIVisualEffectView()
        view.effect = UIBlurEffect(style: .regular)
        view.backgroundColor = UIColor.white.withAlphaComponent(0.85)
        view.clipsToBounds = true
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        searchBar.insertSubview(view, at: 0)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: searchTextField.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: searchTextField.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: searchTextField.bottomAnchor),
            view.topAnchor.constraint(equalTo: searchTextField.topAnchor)
        ])
    }
    
    private func configureTableView() {
        tableView.delegate = self
        let nib = UINib(nibName: String(describing: SongTableViewCell.self), bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: SongTableViewCell.cellIdentifier)
    }
    
    private func setupSnapshot() {
        snapshot = NSDiffableDataSourceSnapshot<Int, Song>()
        snapshot.appendSections([0])
        
        if !searchText.isEmpty {
            filteredSongs = songs.filter { $0.name!.range(of: searchText, options: .caseInsensitive) != nil }
        } else {
            filteredSongs = songs
        }
        
        snapshot.appendItems(filteredSongs)
        DispatchQueue.main.async {
            self.dataSource?.apply(self.snapshot, animatingDifferences: true)
        }
    }
    
    private func setupDiffableDataSource() {
        dataSource = UITableViewDiffableDataSource<Int, Song>(tableView: tableView, cellProvider: { (tableView, indexPath, song) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: SongTableViewCell.cellIdentifier) as! SongTableViewCell
            cell.configure(name: song.name, author: song.author?.name, imageURL: song.thumbnails?.smallUrl, index: indexPath.row + 1)
            return cell
        })
        setupSnapshot()
    }
}

//MARK: - NSFetchedResultsControllerDelegate
extension PlayerSongsListViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        setupSnapshot()
    }
}

//MARK: - UITableViewDelegate
extension PlayerSongsListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        audioPlayer.setupPlayer(at: indexPath.row)
    }
}

//MARK: - UISearchBarDelegate
extension PlayerSongsListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(search), object: nil)
        self.searchText = searchText
        perform(#selector(search), with: nil, afterDelay: 0.5)
    }
    
    @objc private func search() {
        setupSnapshot()
    }
}


//MARK: - Actions
extension PlayerSongsListViewController {
    /// Tracks down Pan Gesture.
    /// Moves the `cardView` to one of the positions, depending on where the view is dragged to.
    @IBAction func viewPanned(_ panRecognizer: UIPanGestureRecognizer) {
        let velocity = panRecognizer.velocity(in: self.view)
        let translation = panRecognizer.translation(in: self.view)
        
        switch panRecognizer.state {
        case .began:
            cardPanStartingTopConstraint = cardViewTopConstraint.constant
            
        case .changed:
            if self.cardPanStartingTopConstraint + translation.y > 30.0 {
                self.cardViewTopConstraint.constant = self.cardPanStartingTopConstraint + translation.y
            }
            
            // change the dimmer view alpha based on how much user has dragged
            dimmerView.alpha = dimAlphaWithCardTopConstraint(value: self.cardViewTopConstraint.constant)
            
        case .ended:
            // If the speed is too high, then the user wants to close the controller.
            if velocity.y > 1500.0 {
                hideCardAndGoBack()
                return
            }
            
            if let safeAreaHeight = window?.safeAreaLayoutGuide.layoutFrame.size.height,
               let bottomPadding = window?.safeAreaInsets.bottom {
                
                if self.cardViewTopConstraint.constant < (safeAreaHeight + bottomPadding) * 0.25 {
                    showCard(atState: .expanded)
                } else if self.cardViewTopConstraint.constant < (safeAreaHeight) - 70 {
                    showCard(atState: .normal)
                } else {
                    hideCardAndGoBack()
                }
            }
        default:
            break
        }
    }
    
    @IBAction func dimmerViewTapped(_ tapRecognizer: UITapGestureRecognizer) {
        hideCardAndGoBack()
    }
}

//MARK: Animations
extension PlayerSongsListViewController {
    
    /// Animates the movement of the cardView depending on the state..
    /// - Parameter atState: CardView deployment position.
    private func showCard(atState: CardViewState = .normal) {
        
        self.view.layoutIfNeeded()
        
        if let safeAreaHeight = window?.safeAreaLayoutGuide.layoutFrame.size.height,
           let bottomPadding = window?.safeAreaInsets.bottom {
            
            if atState == .expanded {
                // if state is expanded, top constraint is 30pt away from safe area top
                cardViewTopConstraint.constant = 30.0
            } else {
                cardViewTopConstraint.constant = (safeAreaHeight + bottomPadding) / 2.0
            }
            
            cardPanStartingTopConstraint = cardViewTopConstraint.constant
        }
        
        // move card up from bottom animator
        let showCard = UIViewPropertyAnimator(duration: 0.25, curve: .easeIn, animations: {
            self.view.layoutIfNeeded()
        })
        
        // animate the dimmerView alpha together with the card move up animation
        showCard.addAnimations {
            self.dimmerView.alpha = 0.5
        }
        
        showCard.startAnimation()
    }
    
    /// Animates the disappearance of the cardView.
    private func hideCardAndGoBack() {
        self.view.layoutIfNeeded()
        
        if let safeAreaHeight = window?.safeAreaLayoutGuide.layoutFrame.size.height,
           let bottomPadding = window?.safeAreaInsets.bottom {
            
            // move the card view to bottom of screen
            cardViewTopConstraint.constant = safeAreaHeight + bottomPadding
        }
        
        // move card down to bottom animator
        let hideCard = UIViewPropertyAnimator(duration: 0.25, curve: .easeIn, animations: {
            self.view.layoutIfNeeded()
        })
        
        // animate the dimmerView alpha together with the card move down animation
        hideCard.addAnimations {
            self.dimmerView.alpha = 0.0
        }
        
        // when the animation completes, dismiss this view controller
        hideCard.addCompletion({ position in
            if position == .end {
                if(self.presentingViewController != nil) {
                    self.dismiss(animated: false, completion: nil)
                }
            }
        })
        
        hideCard.startAnimation()
    }
    
    /// Calculates the opacity of the dimmerView based on the distance to the top.
    /// If the cardView rises above the `.normal` state, the transparency does not change.
    /// - Parameter value: `CardView` distance to top.
    /// - Returns: The calculated transparency of the `dimmerView`..
    private func dimAlphaWithCardTopConstraint(value: CGFloat) -> CGFloat {
        let fullDimAlpha : CGFloat = 0.5
        
        // ensure safe area height and safe area bottom padding is not nil
        guard let safeAreaHeight = window?.safeAreaLayoutGuide.layoutFrame.size.height,
              let bottomPadding = window?.safeAreaInsets.bottom else {
            return fullDimAlpha
        }
        
        // when card view top constraint value is equal to this,
        // the dimmer view alpha is dimmest (0.5)
        let fullDimPosition = (safeAreaHeight + bottomPadding) / 2.0
        
        // when card view top constraint value is equal to this,
        // the dimmer view alpha is lightest (0.0)
        let noDimPosition = safeAreaHeight + bottomPadding
        
        // if card view top constraint is lesser than fullDimPosition
        // it is dimmest
        if value < fullDimPosition {
            return fullDimAlpha
        }
        
        // if card view top constraint is more than noDimPosition
        // it is dimmest
        if value > noDimPosition {
            return 0.0
        }
        
        // else return an alpha value in between 0.0 and 0.5 based on the top constraint value
        return fullDimAlpha * 1 - ((value - fullDimPosition) / fullDimPosition)
    }
}

//MARK: - Supporting Methods
extension PlayerSongsListViewController {
    
    /// Configures pan gesture for adjusting cardViewState.
    private func configurePanGesture() {
        let viewPan = UIPanGestureRecognizer(target: self, action: #selector(viewPanned(_:)))
        viewPan.delaysTouchesBegan = false
        viewPan.delaysTouchesEnded = false
        self.view.addGestureRecognizer(viewPan)
    }
    
    /// Configures the Tap Gesture to close the controller when the dimmerView is pressed.
    private func configureTapGesture() {
        let dimmerTap = UITapGestureRecognizer(target: self, action: #selector(dimmerViewTapped(_:)))
        dimmerView.addGestureRecognizer(dimmerTap)
        dimmerView.isUserInteractionEnabled = true
    }
    
    private func configureViews() {
        backingImageView.image = backingImage

        cardView.clipsToBounds = true
        cardView.layer.cornerRadius = 10.0
        cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        handleView.clipsToBounds = true
        handleView.layer.cornerRadius = handleView.frame.height / 2

        if let safeAreaHeight = window?.safeAreaLayoutGuide.layoutFrame.size.height,
           let bottomPadding = window?.safeAreaInsets.bottom {
            cardViewTopConstraint.constant = safeAreaHeight + bottomPadding
        }
        dimmerView.alpha = 0.0
    }
}
